const axios = require('axios');

// =========================
// LISTAS DE PALAVRAS
// =========================

// Ofensas a grupos: bloqueadas em nomes de usuário e em reviews.
// Só termos sem uso legítimo comum (ex.: "veado" e "macaco" ficam de fora,
// a moderação da OpenAI avalia o contexto desses casos nas reviews).
const SLURS = [
  'viado', 'boiola', 'baitola', 'traveco', 'retardado', 'mongoloide',
  'crioulo', 'nigger', 'nigga', 'faggot',
];

// Palavrões e termos impróprios: bloqueados só em nomes de usuário
// (em reviews, palavrão contra o jogo é aceito).
const USERNAME_ONLY = [
  'hitler', 'nazi', 'nazista', 'puta', 'vadia', 'piranha', 'arrombado',
  'caralho', 'porra', 'merda', 'foder', 'fodase', 'buceta', 'cuzao',
  'corno', 'otario', 'bicha', 'sapatao', 'fdp', 'vsf', 'pqp',
];

// Troca acentos e "leetspeak" (v14d0 → viado) antes de comparar
function normalizeText(text) {
  return String(text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[4@]/g, 'a')
    .replace(/3/g, 'e')
    .replace(/[1!|]/g, 'i')
    .replace(/0/g, 'o')
    .replace(/[5$]/g, 's')
    .replace(/7/g, 't');
}

// Palavras curtas só contam no começo/fim de um trecho do nome, para não
// pegar "puta" dentro de "computador"; as longas contam em qualquer posição.
function usernameHasBlockedWord(username) {
  const normalized = normalizeText(username);
  const compact = normalized.replace(/[^a-z]/g, '');
  const tokens = normalized.split(/[^a-z]+/).filter(Boolean);

  return [...SLURS, ...USERNAME_ONLY].some((word) =>
    word.length >= 5
      ? compact.includes(word)
      : tokens.some((t) => t.startsWith(word) || t.endsWith(word))
  );
}

function textHasSlur(text) {
  const tokens = normalizeText(text).split(/[^a-z]+/);
  return SLURS.some((word) => tokens.includes(word));
}

// =========================
// OPENAI MODERATION
// =========================

// Calibrado com reviews reais em português: violência, palavrão e
// "morri de tédio" são normais em reviews de jogos e NÃO bloqueiam.
// Ofensas a grupos ficaram com hate >= 0.10; textos aceitáveis, <= 0.04.
const HATE_THRESHOLD = 0.08;
const HARASSMENT_THRESHOLD = 0.9;
const ALWAYS_BLOCK = ['harassment/threatening', 'hate/threatening', 'sexual/minors'];

async function openAiFlags(text) {
  const response = await axios.post(
    'https://api.openai.com/v1/moderations',
    { model: 'omni-moderation-latest', input: text },
    {
      headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}` },
      timeout: 8000,
    }
  );

  const { categories, category_scores: scores } = response.data.results[0];

  return (
    scores.hate >= HATE_THRESHOLD ||
    scores.harassment >= HARASSMENT_THRESHOLD ||
    ALWAYS_BLOCK.some((category) => categories[category])
  );
}

// Retorna true se a review deve ser recusada. Se a OpenAI falhar
// (fora do ar, limite do plano gratuito), vale só a lista de palavras,
// para a review nunca travar por causa do serviço externo.
async function isReviewBlocked(text) {
  if (textHasSlur(text)) return true;

  if (!process.env.OPENAI_API_KEY || !String(text || '').trim()) return false;

  try {
    return await openAiFlags(text);
  } catch (err) {
    console.log('Moderação OpenAI indisponível:', err.response?.status || err.message);
    return false;
  }
}

module.exports = { usernameHasBlockedWord, isReviewBlocked };
