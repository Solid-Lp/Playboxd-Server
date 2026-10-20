const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const axios = require('axios');

require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
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


// =========================
// MIDDLEWARE AUTH
// =========================

function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token não fornecido',
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token inválido',
    });
  }
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

app.post('/register', async (req, res) => {

  try {

    const { username, email, password } = req.body;

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await pool.query(
      'SELECT * FROM users WHERE LOWER(email) = $1',
      [normalizedEmail]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email já cadastrado',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await pool.query(
      `INSERT INTO users (username, email, password)
       VALUES ($1, $2, $3)
       RETURNING id, username, email`,
      [username, normalizedEmail, hashedPassword]
    );

    const token = jwt.sign(
      { id: newUser.rows[0].id },
      process.env.JWT_SECRET
    );

    res.json({
      success: true,
      token,
      user: newUser.rows[0],
    });

  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, error: error.message });
  }
});


// =========================
// LOGIN
// =========================

app.post('/login', async (req, res) => {

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

    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(400).json({
        success: false,
        message: 'Senha incorreta',
      });
    }

    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
      },
    });

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
      fields name, cover.url, rating, summary, genres.name;
      limit 20;
      where cover != null & total_rating_count > 50;
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
      fields name, cover.url, first_release_date, rating, summary, genres.name;
      where cover != null & first_release_date != null;
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
      fields name, cover.url, rating, summary, genres.name;
      where cover != null;
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
      fields name, cover.url, rating, summary, genres.name;
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

app.post('/library', authMiddleware, async (req, res) => {

  try {

    const { game_id, game_name, cover_url, status, progress } = req.body;

    const result = await pool.query(
      `INSERT INTO library (user_id, game_id, game_name, cover_url, status, progress)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, game_id)
       DO UPDATE SET status = $5, progress = $6
       RETURNING *`,
      [req.userId, game_id, game_name, cover_url, status || 'playing', progress || 0]
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

app.post('/reviews', authMiddleware, async (req, res) => {

  try {

    const { game_id, game_name, cover_url, rating, review_text } = req.body;

    const result = await pool.query(
      `INSERT INTO reviews (user_id, game_id, game_name, cover_url, rating, review_text)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.userId, game_id, game_name, cover_url, rating, review_text]
    );

    res.json({ success: true, data: result.rows[0] });

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
      `SELECT r.id, r.game_id, r.game_name, r.cover_url, r.rating, r.review_text, r.created_at, u.username
       FROM reviews r
       JOIN users u ON u.id = r.user_id
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
});