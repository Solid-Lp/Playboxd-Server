const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const { OAuth2Client } = require('google-auth-library');
const crypto = require('crypto');
const { rateLimit } = require('express-rate-limit');
const { usernameHasBlockedWord, isReviewBlocked } = require('./moderation');

require('dotenv').config();

const googleClient = new OAuth2Client();

// O plano gratuito do Render bloqueia SMTP (portas 25/465/587), então os
// e-mails saem pela API HTTPS do Brevo.
async function sendEmail({ to, toName, subject, text, html }) {
  await axios.post(
    'https://api.brevo.com/v3/smtp/email',
    {
      sender: { name: 'Playboxd', email: process.env.EMAIL_USER },
      to: [{ email: to, name: toName }],
      subject,
      textContent: text,
      htmlContent: html,
    },
    {
      headers: {
        'api-key': process.env.BREVO_API_KEY,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    }
  );
}

const app = express();

// O Render fica atrás de um proxy: sem isso, todo mundo teria o mesmo IP
app.set('trust proxy', 1);

app.use(cors());
app.use(express.json());


// =========================
// LIMITE DE TENTATIVAS
// =========================

function limiter(windowMinutes, limit, keyGenerator) {
  return rateLimit({
    windowMs: windowMinutes * 60 * 1000,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    ...(keyGenerator && { keyGenerator }),
    message: {
      success: false,
      message: 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
    },
  });
}

// Por IP
const authLimiter = limiter(15, 10);
// Protege a cota de e-mails do Brevo
const emailLimiter = limiter(60, 5);
// Cada código já aceita só 5 tentativas; isto limita a troca de códigos
const codeLimiter = limiter(15, 15);
// Por usuário (usar depois do authMiddleware); protege a cota da OpenAI
const writeLimiter = limiter(60, 20, (req) => `user:${req.userId}`);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false },
});


// =========================
// TWITCH / IGDB
// =========================

let twitchToken = null;
let twitchTokenExpiresAt = 0;

async function getTwitchToken() {
  if (twitchToken && Date.now() < twitchTokenExpiresAt) {
    return twitchToken;
  }

  const response = await axios.post('https://id.twitch.tv/oauth2/token', null, {
    params: {
      client_id: process.env.TWITCH_CLIENT_ID,
      client_secret: process.env.TWITCH_CLIENT_SECRET,
      grant_type: 'client_credentials',
    },
  });

  twitchToken = response.data.access_token;
  twitchTokenExpiresAt = Date.now() + (response.data.expires_in - 60) * 1000;

  return twitchToken;
}

async function igdbQuery(body, retry = true) {
  const token = await getTwitchToken();

  try {
    const response = await axios.post('https://api.igdb.com/v4/games', body, {
      headers: {
        'Client-ID': process.env.TWITCH_CLIENT_ID,
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'text/plain',
      },
    });

    return response.data;
  } catch (err) {
    if (retry && err.response?.status === 401) {
      twitchToken = null;
      return igdbQuery(body, false);
    }
    throw err;
  }
}

// Tipos da IGDB que aparecem no app (sem DLC, bundle, mod, episódio, pack, update)
const ALLOWED_GAME_TYPES = [0, 2, 4, 8, 9, 10, 11];
const GAME_TYPE_FILTER = `game_type = (${ALLOWED_GAME_TYPES.join(',')})`;

// Busca nome e capa na IGDB, para não confiar nos dados enviados pelo app.
// Retorna { game } ou { status, message } quando o jogo não pode ser usado.
async function fetchGame(gameId) {
  const id = Number(gameId);
  if (!Number.isInteger(id) || id <= 0) {
    return { status: 400, message: 'Jogo inválido' };
  }

  let data;
  try {
    data = await igdbQuery(`fields name, cover.url, game_type; where id = ${id};`);
  } catch (err) {
    console.log('Erro ao buscar jogo na IGDB:', err.response?.data || err.message);
    return { status: 503, message: 'Não foi possível verificar o jogo. Tente novamente.' };
  }

  const game = data[0];
  if (!game) {
    return { status: 400, message: 'Jogo não encontrado' };
  }

  if (game.game_type != null && !ALLOWED_GAME_TYPES.includes(game.game_type)) {
    return { status: 400, message: 'Este item não é um jogo (DLC, pacote ou similar).' };
  }

  // Mesmo formato de capa que o app usa
  const coverUrl = game.cover?.url
    ? `https:${game.cover.url}`.replace('t_thumb', 't_1080p')
    : null;

  return { game: { id, name: game.name, cover_url: coverUrl } };
}


// =========================
// MIDDLEWARE AUTH
// =========================

async function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token não fornecido',
    });
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token inválido',
    });
  }

  try {
    // token_version muda ao redefinir a senha, derrubando sessões antigas.
    // Tokens antigos (sem tv) contam como versão 0.
    const result = await pool.query(
      'SELECT token_version FROM users WHERE id = $1',
      [decoded.id]
    );

    if (result.rows.length === 0 || result.rows[0].token_version !== (decoded.tv ?? 0)) {
      return res.status(401).json({
        success: false,
        message: 'Sessão expirada. Faça login novamente.',
      });
    }
  } catch (error) {
    console.log(error);
    return res.status(500).json({ success: false, message: 'Erro no servidor' });
  }

  req.userId = decoded.id;
  next();
}


// =========================
// CÓDIGOS POR E-MAIL (verificação e recuperação de senha)
// =========================

const CODE_TTL_MINUTES = 15;
const CODE_MAX_ATTEMPTS = 5;
const CODE_RESEND_SECONDS = 60;
const MIN_PASSWORD_LENGTH = 6;

const CODE_EMAILS = {
  verify: {
    subject: 'Seu código de verificação do Playboxd',
    intro: 'Use o código abaixo para confirmar seu e-mail no Playboxd:',
  },
  reset: {
    subject: 'Recuperação de senha do Playboxd',
    intro: 'Recebemos um pedido para redefinir a senha da sua conta. Use o código abaixo no app:',
  },
};

function authResponse(user) {
  const token = jwt.sign(
    { id: user.id, tv: user.token_version ?? 0 },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    success: true,
    token,
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      avatar_url: user.avatar_url,
    },
  };
}

// Gera um novo código, invalida os anteriores e envia por e-mail.
// Retorna false se um código foi enviado há menos de CODE_RESEND_SECONDS.
async function sendEmailCode(user, purpose) {

  const recent = await pool.query(
    `SELECT 1 FROM email_codes
     WHERE user_id = $1 AND purpose = $2
       AND created_at > NOW() - make_interval(secs => $3)`,
    [user.id, purpose, CODE_RESEND_SECONDS]
  );

  if (recent.rows.length > 0) return false;

  const code = crypto.randomInt(0, 1000000).toString().padStart(6, '0');
  const codeHash = await bcrypt.hash(code, 10);

  await pool.query(
    'DELETE FROM email_codes WHERE user_id = $1 AND purpose = $2',
    [user.id, purpose]
  );

  await pool.query(
    `INSERT INTO email_codes (user_id, purpose, code_hash, expires_at)
     VALUES ($1, $2, $3, NOW() + make_interval(mins => $4))`,
    [user.id, purpose, codeHash, CODE_TTL_MINUTES]
  );

  const { subject, intro } = CODE_EMAILS[purpose];

  // O nome de usuário é digitado pelo usuário: escapa antes de pôr no HTML
  const safeName = String(user.username).replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

  try {
    await sendEmail({
      to: user.email,
      toName: user.username,
      subject,
      text: `Olá, ${user.username}!\n\n${intro}\n\n${code}\n\nO código expira em ${CODE_TTL_MINUTES} minutos. Se você não fez esse pedido, ignore este e-mail.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; background: #020817; color: #e6e6e6; border-radius: 16px;">
          <h1 style="color: #39ff14; margin: 0 0 16px;">PLAYBOXD</h1>
          <p>Olá, ${safeName}!</p>
          <p>${intro}</p>
          <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #39ff14; text-align: center; margin: 24px 0;">${code}</p>
          <p style="color: #9aa4b2; font-size: 13px;">O código expira em ${CODE_TTL_MINUTES} minutos. Se você não fez esse pedido, ignore este e-mail.</p>
        </div>`,
    });
  } catch (err) {
    // Sem isso o código não enviado bloquearia um novo pedido por CODE_RESEND_SECONDS
    await pool.query(
      'DELETE FROM email_codes WHERE user_id = $1 AND purpose = $2',
      [user.id, purpose]
    );
    console.log('Erro no envio pelo Brevo:', err.response?.data || err.message);
    throw err;
  }

  return true;
}

// Confere o código; em caso de erro devolve a mensagem para o usuário
async function checkEmailCode(userId, purpose, code) {

  const result = await pool.query(
    `SELECT * FROM email_codes
     WHERE user_id = $1 AND purpose = $2
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId, purpose]
  );

  const entry = result.rows[0];

  if (!entry || new Date(entry.expires_at) < new Date()) {
    return 'Código expirado. Peça um novo código.';
  }

  if (entry.attempts >= CODE_MAX_ATTEMPTS) {
    return 'Muitas tentativas. Peça um novo código.';
  }

  const valid = await bcrypt.compare(String(code || '').trim(), entry.code_hash);

  if (!valid) {
    await pool.query(
      'UPDATE email_codes SET attempts = attempts + 1 WHERE id = $1',
      [entry.id]
    );
    return 'Código incorreto';
  }

  await pool.query(
    'DELETE FROM email_codes WHERE user_id = $1 AND purpose = $2',
    [userId, purpose]
  );

  return null;
}

// Cadastros nunca confirmados são apagados depois de 24 h (os códigos saem
// junto pelo ON DELETE CASCADE). Bem mais que a validade do código, para não
// apagar a conta de quem só pediu "Reenviar código" um pouco depois.
async function cleanupUnverifiedUsers() {
  const result = await pool.query(
    `DELETE FROM users
     WHERE email_verified = false
       AND created_at < NOW() - INTERVAL '24 hours'`
  );
  return result.rowCount;
}

async function findUserByEmail(email) {
  const result = await pool.query(
    'SELECT * FROM users WHERE LOWER(email) = $1',
    [String(email || '').trim().toLowerCase()]
  );
  return result.rows[0];
}

const USERNAME_MIN = 3;
const USERNAME_MAX = 20;

// Retorna a mensagem de erro para o usuário, ou null se o nome for válido.
// excludeUserId: dono atual do nome (pode manter o próprio nome).
async function validateUsername(username, excludeUserId) {
  const name = String(username || '').trim();

  if (name.length < USERNAME_MIN || name.length > USERNAME_MAX) {
    return `O nome deve ter entre ${USERNAME_MIN} e ${USERNAME_MAX} caracteres`;
  }

  if (!/^[\p{L}\p{N} _.-]+$/u.test(name)) {
    return 'Use apenas letras, números, espaço, ponto, hífen ou _';
  }

  if (usernameHasBlockedWord(name)) {
    return 'Este nome de usuário não é permitido. Escolha outro.';
  }

  const taken = await pool.query(
    'SELECT 1 FROM users WHERE LOWER(username) = LOWER($1) AND id <> $2',
    [name, excludeUserId || 0]
  );

  if (taken.rows.length > 0) {
    return 'Este nome de usuário já está em uso';
  }

  return null;
}


// =========================
// TESTE API
// =========================

app.get('/', async (req, res) => {
  res.json({
    success: true,
    message: 'PLAYBOXED API ONLINE',
  });
});


// =========================
// REGISTER
// =========================

app.post('/register', authLimiter, async (req, res) => {

  try {

    const { email, password } = req.body;

    const username = String(req.body.username || '').trim();

    const normalizedEmail = email.trim().toLowerCase();

    if (!password || password.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        success: false,
        message: `A senha deve ter pelo menos ${MIN_PASSWORD_LENGTH} caracteres`,
      });
    }

    await cleanupUnverifiedUsers();

    const existingUser = await findUserByEmail(normalizedEmail);

    if (existingUser && existingUser.email_verified) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado',
      });
    }

    const usernameError = await validateUsername(username, existingUser?.id);

    if (usernameError) {
      return res.status(400).json({ success: false, message: usernameError });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // E-mail ainda não confirmado não conta como cadastrado: refaz o cadastro.
    // É seguro porque conta não confirmada nunca recebeu token (sem dados).
    const userQuery = existingUser
      ? await pool.query(
          `UPDATE users SET username = $1, password = $2
           WHERE id = $3
           RETURNING *`,
          [username, hashedPassword, existingUser.id]
        )
      : await pool.query(
          `INSERT INTO users (username, email, password, email_verified)
           VALUES ($1, $2, $3, false)
           RETURNING *`,
          [username, normalizedEmail, hashedPassword]
        );

    let emailSent = true;

    try {
      await sendEmailCode(userQuery.rows[0], 'verify');
    } catch (err) {
      console.log('Erro ao enviar código de verificação:', err.message);
      emailSent = false;
    }

    res.json({
      success: true,
      needsVerification: true,
      email: normalizedEmail,
      message: emailSent
        ? 'Enviamos um código para o seu e-mail'
        : 'Conta criada, mas não foi possível enviar o código. Toque em "Reenviar código".',
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LOGIN
// =========================

app.post('/login', authLimiter, async (req, res) => {

  try {

    const { email, password } = req.body;

    const userQuery = await pool.query(
      'SELECT * FROM users WHERE LOWER(email) = LOWER($1)',
      [email.trim()]
    );

    if (userQuery.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Usuário não encontrado',
      });
    }

    const user = userQuery.rows[0];

    if (!user.password) {
      return res.status(400).json({
        success: false,
        message: 'Esta conta usa login com Google',
      });
    }

    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(400).json({
        success: false,
        message: 'Senha incorreta',
      });
    }

    if (!user.email_verified) {
      try {
        await sendEmailCode(user, 'verify');
      } catch (err) {
        console.log('Erro ao enviar código de verificação:', err.message);
      }

      return res.status(403).json({
        success: false,
        needsVerification: true,
        email: user.email,
        message: 'Confirme seu e-mail para entrar. Enviamos um código para você.',
      });
    }

    res.json(authResponse(user));

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LOGIN COM GOOGLE
// =========================

app.post('/auth/google', authLimiter, async (req, res) => {

  try {

    const { idToken } = req.body;

    let payload;

    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: 'Token do Google inválido',
      });
    }

    if (!payload.email || !payload.email_verified) {
      return res.status(401).json({
        success: false,
        message: 'E-mail do Google não verificado',
      });
    }

    const googleId = payload.sub;
    const email = payload.email.trim().toLowerCase();

    let userQuery = await pool.query(
      'SELECT * FROM users WHERE google_id = $1',
      [googleId]
    );

    // Mesmo e-mail de uma conta com senha: vincula ao Google
    if (userQuery.rows.length === 0) {
      userQuery = await pool.query(
        `UPDATE users SET google_id = $1, email_verified = true
         WHERE LOWER(email) = $2
         RETURNING *`,
        [googleId, email]
      );
    }

    if (userQuery.rows.length === 0) {
      // Nome do Google impróprio: usa a parte antes do @, ou um nome neutro
      const emailName = email.split('@')[0];
      const username = [payload.name, emailName]
        .find((name) => name && !usernameHasBlockedWord(name))
        || `player${crypto.randomInt(10000, 100000)}`;

      userQuery = await pool.query(
        `INSERT INTO users (username, email, password, google_id, avatar_url, email_verified, username_set)
         VALUES ($1, $2, NULL, $3, $4, true, false)
         RETURNING *`,
        [username, email, googleId, payload.picture || null]
      );
    }

    const user = userQuery.rows[0];

    // Conta criada pelo Google ainda usa o nome do Google: o app pede um nome
    res.json({
      ...authResponse(user),
      needsUsername: !user.username_set,
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// TROCAR NOME DE USUÁRIO
// =========================

app.patch('/profile/username', authMiddleware, writeLimiter, async (req, res) => {

  try {

    const username = String(req.body.username || '').trim();

    const error = await validateUsername(username, req.userId);

    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const result = await pool.query(
      `UPDATE users SET username = $1, username_set = true
       WHERE id = $2
       RETURNING username`,
      [username, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Usuário não encontrado' });
    }

    res.json({ success: true, username: result.rows[0].username });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// SESSÃO ATUAL (o app chama ao abrir e recebe um token novo de 7 dias)
// =========================

app.get('/me', authMiddleware, async (req, res) => {

  try {

    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);

    const user = result.rows[0];

    res.json({ ...authResponse(user), needsUsername: !user.username_set });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// VERIFICAÇÃO DE E-MAIL
// =========================

app.post('/verify-email', codeLimiter, async (req, res) => {

  try {

    const { email, code } = req.body;

    const user = await findUserByEmail(email);

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Usuário não encontrado',
      });
    }

    // Sem isso, qualquer um com o e-mail de uma conta verificada receberia um token
    if (user.email_verified) {
      return res.status(400).json({
        success: false,
        message: 'Este e-mail já foi verificado. Faça login.',
      });
    }

    const error = await checkEmailCode(user.id, 'verify', code);

    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    await pool.query(
      'UPDATE users SET email_verified = true WHERE id = $1',
      [user.id]
    );

    res.json(authResponse(user));

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/resend-code', emailLimiter, async (req, res) => {

  try {

    const { email, purpose } = req.body;

    if (!CODE_EMAILS[purpose]) {
      return res.status(400).json({ success: false, message: 'Pedido inválido' });
    }

    const user = await findUserByEmail(email);

    // Resposta igual mesmo sem conta, para não revelar e-mails cadastrados
    if (user && !(purpose === 'verify' && user.email_verified)) {
      const sent = await sendEmailCode(user, purpose);

      if (!sent) {
        return res.status(429).json({
          success: false,
          message: `Aguarde ${CODE_RESEND_SECONDS} segundos para pedir outro código`,
        });
      }
    }

    res.json({ success: true, message: 'Se o e-mail estiver cadastrado, enviamos um novo código' });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, message: 'Não foi possível enviar o e-mail. Tente novamente.' });
  }
});


// =========================
// ESQUECI MINHA SENHA
// =========================

app.post('/forgot-password', emailLimiter, async (req, res) => {

  try {

    const user = await findUserByEmail(req.body.email);

    // Resposta igual mesmo sem conta, para não revelar e-mails cadastrados
    if (user) {
      await sendEmailCode(user, 'reset');
    }

    res.json({ success: true, message: 'Se o e-mail estiver cadastrado, enviamos um código' });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, message: 'Não foi possível enviar o e-mail. Tente novamente.' });
  }
});

app.post('/reset-password', codeLimiter, async (req, res) => {

  try {

    const { email, code, newPassword } = req.body;

    if (!newPassword || newPassword.length < MIN_PASSWORD_LENGTH) {
      return res.status(400).json({
        success: false,
        message: `A senha deve ter pelo menos ${MIN_PASSWORD_LENGTH} caracteres`,
      });
    }

    const user = await findUserByEmail(email);

    if (!user) {
      return res.status(400).json({ success: false, message: 'Código incorreto' });
    }

    const error = await checkEmailCode(user.id, 'reset', code);

    if (error) {
      return res.status(400).json({ success: false, message: error });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Quem recebeu o código provou ser dono do e-mail.
    // token_version + 1 derruba as sessões abertas com a senha antiga.
    await pool.query(
      `UPDATE users
       SET password = $1, email_verified = true, token_version = token_version + 1
       WHERE id = $2`,
      [hashedPassword, user.id]
    );

    res.json({ success: true, message: 'Senha alterada! Faça login com a nova senha.' });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// POPULAR GAMES
// =========================

app.get('/popular-games', async (req, res) => {

  try {

    const data = await igdbQuery(`
      fields name, cover.url, rating, summary, genres.name,
        platforms.abbreviation, platforms.name, platforms.platform_family;
      limit 20;
      where cover != null & total_rating_count > 50 & ${GAME_TYPE_FILTER};
      sort total_rating desc;
    `);

    res.json({ success: true, data });

  } catch (err) {
    console.log(err.response?.data || err.message);
    res.status(502).json({ success: false, error: err.message });
  }
});


// =========================
// NEW RELEASES
// =========================

app.get('/new-releases', async (req, res) => {

  try {

    const data = await igdbQuery(`
      fields name, cover.url, first_release_date, rating, summary, genres.name,
        platforms.abbreviation, platforms.name, platforms.platform_family;
      where cover != null & first_release_date != null & ${GAME_TYPE_FILTER};
      sort first_release_date desc;
      limit 20;
    `);

    res.json({ success: true, data });

  } catch (err) {
    console.log(err.response?.data || err.message);
    res.status(502).json({ success: false, error: err.message });
  }
});


// =========================
// SEARCH GAMES
// =========================

app.get('/search-games', async (req, res) => {

  try {

    const { q } = req.query;

    if (!q || q.trim() === '') {
      return res.json({ success: true, data: [] });
    }

    const safeQuery = q.replace(/"/g, '');

    const data = await igdbQuery(`
      search "${safeQuery}";
      fields name, cover.url, rating, summary, genres.name,
        platforms.abbreviation, platforms.name, platforms.platform_family;
      where cover != null & ${GAME_TYPE_FILTER};
      limit 20;
    `);

    res.json({ success: true, data });

  } catch (err) {
    console.log(err.response?.data || err.message);
    res.status(502).json({ success: false, error: err.message });
  }
});


// =========================
// GAME BY ID
// =========================

app.get('/games/:id', async (req, res) => {

  try {

    const id = parseInt(req.params.id, 10);

    if (Number.isNaN(id)) {
      return res.status(400).json({ success: false, error: 'id inválido' });
    }

    const data = await igdbQuery(`
      fields name, cover.url, rating, summary, genres.name,
        platforms.abbreviation, platforms.name, platforms.platform_family;
      where id = ${id};
    `);

    if (!data.length) {
      return res.status(404).json({ success: false, error: 'Jogo não encontrado' });
    }

    res.json({ success: true, data: data[0] });

  } catch (err) {
    console.log(err.response?.data || err.message);
    res.status(502).json({ success: false, error: err.message });
  }
});


// =========================
// LIBRARY - GET
// =========================

app.get('/library', authMiddleware, async (req, res) => {

  try {

    const result = await pool.query(
      `SELECT * FROM library
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.userId]
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LIBRARY - ADD
// =========================

const LIBRARY_STATUSES = ['playing', 'completed', 'dropped'];

// Campos ausentes (undefined) são aceitos; quem chama decide o padrão
function validateLibraryInput(status, progress) {
  if (status !== undefined && !LIBRARY_STATUSES.includes(status)) {
    return 'Status inválido';
  }
  if (progress !== undefined && (!Number.isInteger(progress) || progress < 0 || progress > 100)) {
    return 'Progresso deve ser um número de 0 a 100';
  }
  return null;
}

app.post('/library', authMiddleware, async (req, res) => {

  try {

    const { game_id, status = 'playing', progress = 0 } = req.body;

    const inputError = validateLibraryInput(status, progress);
    if (inputError) {
      return res.status(400).json({ success: false, message: inputError });
    }

    // Nome e capa vêm da IGDB, não do app
    const { game, status: errorStatus, message } = await fetchGame(game_id);
    if (!game) {
      return res.status(errorStatus).json({ success: false, message });
    }

    const result = await pool.query(
      `INSERT INTO library (user_id, game_id, game_name, cover_url, status, progress)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, game_id)
       DO UPDATE SET status = $5, progress = $6
       RETURNING *`,
      [req.userId, game.id, game.name, game.cover_url, status, progress]
    );

    res.json({ success: true, data: result.rows[0] });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LIBRARY - UPDATE STATUS/PROGRESS
// =========================

app.patch('/library/:game_id', authMiddleware, async (req, res) => {

  try {

    const { game_id } = req.params;
    const { status, progress } = req.body;

    const inputError = validateLibraryInput(status ?? undefined, progress ?? undefined);
    if (inputError) {
      return res.status(400).json({ success: false, message: inputError });
    }

    const result = await pool.query(
      `UPDATE library
       SET status = COALESCE($1, status),
           progress = COALESCE($2, progress)
       WHERE user_id = $3 AND game_id = $4
       RETURNING *`,
      [status, progress, req.userId, game_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Jogo não encontrado na biblioteca',
      });
    }

    res.json({ success: true, data: result.rows[0] });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LIBRARY - REMOVE
// =========================

app.delete('/library/:game_id', authMiddleware, async (req, res) => {

  try {

    const { game_id } = req.params;

    await pool.query(
      `DELETE FROM library
       WHERE user_id = $1 AND game_id = $2`,
      [req.userId, game_id]
    );

    res.json({ success: true, message: 'Jogo removido da biblioteca' });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// REVIEWS - POPULAR (público, pra Home)
// =========================

app.get('/reviews/popular', async (req, res) => {

  try {

    const result = await pool.query(
      `SELECT r.id, r.game_id, r.game_name, r.cover_url, r.rating, r.review_text, r.created_at, u.username
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       ORDER BY r.created_at DESC
       LIMIT 10`
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// =========================
// REVIEWS - CREATE
// =========================

const REVIEW_MAX_LENGTH = 2000;

const REVIEW_BLOCKED_MESSAGE = 'Sua review contém linguagem ofensiva ou discriminatória. '
  + 'Critique o jogo à vontade, mas sem ofender pessoas ou grupos.';

// Retorna { rating, text } válidos ou { error }
function validateReviewInput(rating, reviewText) {
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { error: 'A nota deve ser de 1 a 5 estrelas' };
  }

  const text = String(reviewText ?? '').trim();
  if (text.length > REVIEW_MAX_LENGTH) {
    return { error: `A review pode ter no máximo ${REVIEW_MAX_LENGTH} caracteres` };
  }

  return { rating, text };
}

app.post('/reviews', authMiddleware, writeLimiter, async (req, res) => {

  try {

    const { game_id } = req.body;

    const input = validateReviewInput(req.body.rating, req.body.review_text);
    if (input.error) {
      return res.status(400).json({ success: false, message: input.error });
    }

    // Nome e capa vêm da IGDB, não do app
    const { game, status, message } = await fetchGame(game_id);
    if (!game) {
      return res.status(status).json({ success: false, message });
    }

    const existing = await pool.query(
      'SELECT 1 FROM reviews WHERE user_id = $1 AND game_id = $2',
      [req.userId, game.id]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'Você já avaliou este jogo' });
    }

    if (await isReviewBlocked(input.text)) {
      return res.status(400).json({ success: false, message: REVIEW_BLOCKED_MESSAGE });
    }

    const result = await pool.query(
      `INSERT INTO reviews (user_id, game_id, game_name, cover_url, rating, review_text)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.userId, game.id, game.name, game.cover_url, input.rating, input.text]
    );

    res.json({ success: true, data: result.rows[0] });

  } catch (error) {
    // Duas reviews enviadas ao mesmo tempo: a restrição única do banco segura
    if (error.code === '23505') {
      return res.status(409).json({ success: false, message: 'Você já avaliou este jogo' });
    }
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// REVIEWS - EDITAR / APAGAR (a review do próprio usuário)
// =========================

app.put('/reviews/:game_id', authMiddleware, writeLimiter, async (req, res) => {

  try {

    const input = validateReviewInput(req.body.rating, req.body.review_text);
    if (input.error) {
      return res.status(400).json({ success: false, message: input.error });
    }

    if (await isReviewBlocked(input.text)) {
      return res.status(400).json({ success: false, message: REVIEW_BLOCKED_MESSAGE });
    }

    const result = await pool.query(
      `UPDATE reviews SET rating = $1, review_text = $2
       WHERE user_id = $3 AND game_id = $4
       RETURNING *`,
      [input.rating, input.text, req.userId, req.params.game_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Review não encontrada' });
    }

    res.json({ success: true, data: result.rows[0] });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/reviews/:game_id', authMiddleware, async (req, res) => {

  try {

    await pool.query(
      'DELETE FROM reviews WHERE user_id = $1 AND game_id = $2',
      [req.userId, req.params.game_id]
    );

    res.json({ success: true, message: 'Review apagada' });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Review do usuário logado para um jogo (null se ainda não avaliou)
app.get('/my-reviews/:game_id', authMiddleware, async (req, res) => {

  try {

    const result = await pool.query(
      `SELECT id, game_id, rating, review_text, created_at
       FROM reviews
       WHERE user_id = $1 AND game_id = $2`,
      [req.userId, req.params.game_id]
    );

    res.json({ success: true, data: result.rows[0] || null });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// MY REVIEWS (do usuário logado, para o perfil)
// =========================

app.get('/my-reviews', authMiddleware, async (req, res) => {

  try {

    const result = await pool.query(
      `SELECT id, game_id, game_name, cover_url, rating, review_text, created_at
       FROM reviews
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.userId]
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// ACTIVITY FEED (do usuário logado)
// =========================

app.get('/activity', authMiddleware, async (req, res) => {

  try {

    const result = await pool.query(
      `
      SELECT 'review' AS type, game_name, cover_url, rating::text AS extra, review_text AS detail, created_at
      FROM reviews
      WHERE user_id = $1

      UNION ALL

      SELECT 'library' AS type, game_name, cover_url, status AS extra, NULL AS detail, created_at
      FROM library
      WHERE user_id = $1

      ORDER BY created_at DESC
      LIMIT 10
      `,
      [req.userId]
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// PROFILE STATS
// =========================

app.get('/profile/stats', authMiddleware, async (req, res) => {

  try {

    const libraryCount = await pool.query(
      'SELECT COUNT(*) FROM library WHERE user_id = $1',
      [req.userId]
    );

    const reviewsCount = await pool.query(
      'SELECT COUNT(*) FROM reviews WHERE user_id = $1',
      [req.userId]
    );

    res.json({
      success: true,
      data: {
        games_played: parseInt(libraryCount.rows[0].count),
        reviews_written: parseInt(reviewsCount.rows[0].count),
        followers: 0,
      },
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});
// =========================
// REVIEWS - POR JOGO
// =========================

app.get('/reviews/:game_id', async (req, res) => {

  try {

    const { game_id } = req.params;

    const result = await pool.query(
      `SELECT r.id, r.game_id, r.game_name, r.cover_url, r.rating, r.review_text, r.created_at, u.username,
              l.status AS library_status
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       LEFT JOIN library l ON l.user_id = r.user_id AND l.game_id = r.game_id
       WHERE r.game_id = $1
       ORDER BY r.created_at DESC
       LIMIT 10`,
      [game_id]
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});
// =========================
// ACCOUNT - DELETE (exigido pela Google Play)
// =========================

app.delete('/account', authMiddleware, async (req, res) => {

  const client = await pool.connect();

  try {

    await client.query('BEGIN');
    await client.query('DELETE FROM reviews WHERE user_id = $1', [req.userId]);
    await client.query('DELETE FROM library WHERE user_id = $1', [req.userId]);
    await client.query('DELETE FROM users WHERE id = $1', [req.userId]);
    await client.query('COMMIT');

    res.json({ success: true, message: 'Conta excluída' });

  } catch (error) {
    await client.query('ROLLBACK');
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  } finally {
    client.release();
  }
});


// =========================
// PÁGINAS PÚBLICAS (Google Play)
// =========================

const CONTACT_EMAIL = process.env.CONTACT_EMAIL || '';

function publicPage(title, body) {
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} - Playboxd</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 720px; margin: 0 auto; padding: 24px 16px; line-height: 1.6; background: #0d0d0d; color: #e6e6e6; }
  h1, h2 { color: #39ff14; }
  a { color: #39ff14; }
</style>
</head>
<body>
<h1>${title}</h1>
${body}
${CONTACT_EMAIL ? `<p>Contato: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a></p>` : ''}
</body>
</html>`;
}

app.get('/privacy', (req, res) => {
  res.send(publicPage('Política de Privacidade', `
<p>Esta política descreve como o aplicativo Playboxd trata os seus dados.</p>

<h2>Dados coletados</h2>
<ul>
  <li>Nome de usuário e e-mail, informados no cadastro.</li>
  <li>Se você entrar com o Google: nome, e-mail, foto de perfil e o identificador da sua conta Google.</li>
  <li>Senha, armazenada apenas de forma criptografada (hash bcrypt).</li>
  <li>Jogos adicionados à biblioteca, status e progresso.</li>
  <li>Reviews e notas que você publica.</li>
</ul>

<h2>Uso dos dados</h2>
<p>Os dados são usados somente para o funcionamento do app: login, biblioteca, reviews e estatísticas do perfil. O e-mail também é usado para enviar códigos de verificação e de recuperação de senha. O nome de usuário aparece junto às suas reviews, que são públicas para outros usuários.</p>

<h2>Serviços que tratam seus dados</h2>
<p>Não vendemos seus dados. Para o app funcionar, usamos prestadores de serviço que tratam os dados apenas em nosso nome e para a finalidade indicada:</p>
<ul>
  <li><strong>Render</strong>: hospedagem do servidor do app.</li>
  <li><strong>Neon</strong>: banco de dados onde ficam sua conta, biblioteca e reviews.</li>
  <li><strong>Brevo</strong>: envio dos e-mails com códigos de verificação e de recuperação de senha (recebe seu e-mail e nome de usuário).</li>
  <li><strong>OpenAI</strong>: moderação automática do texto das reviews, para bloquear conteúdo ofensivo ou discriminatório.</li>
  <li><strong>Google</strong>: login com Google, quando você escolhe essa opção.</li>
</ul>
<p>Alguns desses serviços ficam fora do Brasil, então seus dados podem ser transferidos e tratados em outros países, com medidas de segurança adequadas.</p>
<p>As informações dos jogos (capas, notas, descrições) vêm da IGDB, e nenhuma informação pessoal é enviada a ela.</p>

<h2>Moderação automática</h2>
<p>Nomes de usuário e reviews passam por filtros automáticos. Conteúdo que viole os <a href="/terms">Termos de Uso</a> pode ser recusado no momento da publicação.</p>

<h2>Segurança</h2>
<p>A comunicação entre o app e o servidor é feita por HTTPS.</p>

<h2>Exclusão</h2>
<p>Você pode excluir sua conta e todos os dados a qualquer momento. Veja <a href="/delete-account">como excluir sua conta</a>.</p>

<h2>Segurança infantil</h2>
<p>Veja nossos <a href="/child-safety">padrões contra abuso e exploração sexual infantil</a>.</p>
`));
});

app.get('/terms', (req, res) => {
  res.send(publicPage('Termos de Uso', `
<p>Bem-vindo ao Playboxd! Ao criar uma conta ou usar o app, você concorda com estes termos. Eles existem para manter a comunidade um lugar bom para todo mundo que gosta de jogos.</p>

<h2>1. Sua conta</h2>
<ul>
  <li>Você precisa ter pelo menos 13 anos para usar o Playboxd.</li>
  <li>Use um e-mail seu e mantenha sua senha em segurança. Você é responsável pelo que acontece na sua conta.</li>
  <li>Escolha um nome de usuário respeitoso e não se passe por outra pessoa.</li>
</ul>

<h2>2. Regras da comunidade</h2>
<p><strong>Critique o jogo, não as pessoas.</strong> Pode dizer que um jogo é ruim, que o final decepcionou ou que não vale o preço. O que não é permitido:</p>
<ul>
  <li><strong>Discurso de ódio</strong>: racismo, homofobia, transfobia, machismo, xenofobia, capacitismo, intolerância religiosa ou qualquer ataque a pessoas por quem elas são.</li>
  <li><strong>Assédio e ameaças</strong>: xingar, humilhar ou ameaçar outros jogadores, desenvolvedores ou qualquer pessoa.</li>
  <li><strong>Conteúdo sexual explícito</strong>, e qualquer conteúdo que sexualize menores (veja nossos <a href="/child-safety">padrões de segurança infantil</a>).</li>
  <li><strong>Spam e propaganda</strong>: links, divulgação ou mensagens repetidas.</li>
  <li><strong>Dados pessoais de outras pessoas</strong>, como telefone, endereço ou redes sociais.</li>
  <li><strong>Spoilers sem aviso</strong>: se for contar algo importante da história, avise no começo da review.</li>
</ul>

<h2>3. Moderação</h2>
<ul>
  <li>Nomes de usuário e reviews passam por filtros automáticos e podem ser recusados se violarem estas regras.</li>
  <li>Podemos remover conteúdo e suspender ou excluir contas que desrespeitem os termos, sem aviso prévio nos casos graves.</li>
  <li>Se encontrar algo que viole as regras${CONTACT_EMAIL ? `, avise pelo e-mail <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>` : ', avise pelo contato informado na página do app na Google Play'}.</li>
</ul>

<h2>4. Seu conteúdo</h2>
<ul>
  <li>Suas reviews são suas, e você é responsável pelo que escreve.</li>
  <li>Ao publicar, você permite que o Playboxd exiba a review e seu nome de usuário para outros usuários do app.</li>
  <li>Se você excluir sua conta, suas reviews e sua biblioteca são apagadas.</li>
</ul>

<h2>5. Sobre o app</h2>
<ul>
  <li>As informações dos jogos vêm da IGDB. Nomes, capas e marcas pertencem aos seus respectivos donos.</li>
  <li>O Playboxd é oferecido como está. Podemos mudar recursos ou ficar fora do ar temporariamente.</li>
  <li>Estes termos podem ser atualizados, e a versão mais recente fica sempre nesta página.</li>
</ul>

<h2>6. Privacidade</h2>
<p>Veja como tratamos seus dados na nossa <a href="/privacy">Política de Privacidade</a>.</p>

<p>Estes termos seguem as leis do Brasil.</p>
`));
});

app.get('/child-safety', (req, res) => {
  res.send(publicPage('Padrões de Segurança Infantil', `
<p>O Playboxd tem tolerância zero com abuso e exploração sexual infantil (CSAE), incluindo material de abuso sexual infantil (CSAM). Estes padrões valem para todo conteúdo publicado no app, como nomes de usuário e reviews.</p>

<h2>Conteúdo e condutas proibidos</h2>
<ul>
  <li>Qualquer material que mostre, promova ou normalize o abuso ou a exploração sexual de menores de 18 anos.</li>
  <li>Conteúdo que sexualize crianças ou adolescentes, inclusive em texto.</li>
  <li>Aliciamento (grooming), tentativa de contato com menores para fins sexuais ou sextorsão.</li>
  <li>Divulgação, solicitação ou links para material de abuso sexual infantil.</li>
</ul>

<h2>Como aplicamos estes padrões</h2>
<ul>
  <li>Conteúdo que viole estes padrões é removido assim que identificado.</li>
  <li>As contas responsáveis são excluídas permanentemente.</li>
  <li>Casos de CSAM ou de risco a crianças são comunicados às autoridades competentes, como a SaferNet Brasil e a Polícia Federal, conforme o Estatuto da Criança e do Adolescente (ECA, Lei nº 8.069/1990) e a legislação aplicável.</li>
  <li>Cooperamos com as autoridades em investigações, nos termos da lei.</li>
</ul>

<h2>Como denunciar</h2>
<p>Se você encontrar no Playboxd qualquer conteúdo ou comportamento que coloque crianças em risco, denuncie imediatamente${CONTACT_EMAIL ? ` pelo e-mail <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>` : ' pelo contato informado na página do app na Google Play'}, informando o nome do usuário e, se possível, o jogo e a review em questão. Todas as denúncias são analisadas com prioridade.</p>
<p>Você também pode denunciar diretamente à <a href="https://new.safernet.org.br/denuncie">SaferNet Brasil</a> ou ligar para o Disque 100 (Direitos Humanos).</p>
`));
});

app.get('/delete-account', (req, res) => {
  res.send(publicPage('Excluir conta', `
<p>Para excluir sua conta do Playboxd:</p>
<ol>
  <li>Abra o app e faça login.</li>
  <li>Vá até a aba <strong>Profile</strong>.</li>
  <li>Toque em <strong>EXCLUIR CONTA</strong> e confirme.</li>
</ol>
<p>Serão apagados permanentemente: sua conta (nome de usuário, e-mail, senha e vínculo com o Google, se houver), sua biblioteca de jogos e todas as suas reviews. Nenhum dado é mantido após a exclusão.</p>
${CONTACT_EMAIL ? '<p>Se não conseguir acessar o app, envie um e-mail a partir do endereço cadastrado pedindo a exclusão.</p>' : ''}
`));
});


// =========================
// TOP RATED GAMES (média do banco)
// =========================

app.get('/top-rated', async (req, res) => {

  try {

    const result = await pool.query(
      `SELECT
        game_id,
        game_name,
        cover_url,
        ROUND(AVG(rating)::numeric, 1) AS avg_rating,
        COUNT(*) AS review_count
       FROM reviews
       GROUP BY game_id, game_name, cover_url
       HAVING COUNT(*) >= 1
       ORDER BY avg_rating DESC, review_count DESC
       LIMIT 10`
    );

    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// START SERVER
// =========================

app.listen(process.env.PORT || 3000, () => {
  console.log('Servidor rodando');

  cleanupUnverifiedUsers()
    .then((count) => {
      if (count > 0) console.log(`Cadastros não confirmados removidos: ${count}`);
    })
    .catch((err) => console.log('Erro na limpeza de cadastros:', err.message));
});