-- =============================================================
-- Playboxd: estrutura do banco de dados (PostgreSQL / Neon)
-- =============================================================
-- Reflete o banco de produção em 2026-11-08.
--
-- Recriar o banco do zero:
--   psql "$DATABASE_URL" -f schema.sql
--
-- Pode ser executado mais de uma vez: só cria o que não existe.
-- Ao mudar a estrutura do banco, atualize este arquivo junto.
-- =============================================================


-- -------------------------------------------------------------
-- Usuários
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id              SERIAL PRIMARY KEY,
  username        TEXT NOT NULL,
  email           TEXT NOT NULL UNIQUE,
  -- NULL em contas criadas só com o Google
  password        TEXT,
  avatar_url      TEXT,
  created_at      TIMESTAMP DEFAULT NOW(),
  google_id       TEXT UNIQUE,
  -- Contas por e-mail só entram depois de confirmar o código
  email_verified  BOOLEAN NOT NULL DEFAULT false,
  -- false: conta criada pelo Google que ainda não escolheu o nome
  username_set    BOOLEAN NOT NULL DEFAULT true
);


-- -------------------------------------------------------------
-- Biblioteca (jogos de cada usuário)
-- -------------------------------------------------------------
-- game_id é o ID do jogo no IGDB.
CREATE TABLE IF NOT EXISTS library (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
  game_id     INTEGER NOT NULL,
  game_name   TEXT NOT NULL,
  game_image  TEXT,  -- legado: não é mais usado pelo código (usa cover_url)
  status      TEXT NOT NULL,  -- 'playing' | 'completed' | 'dropped'
  created_at  TIMESTAMP DEFAULT NOW(),
  cover_url   TEXT,
  progress    INTEGER DEFAULT 0,
  CONSTRAINT library_user_game_unique UNIQUE (user_id, game_id)
);


-- -------------------------------------------------------------
-- Reviews
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
  id           SERIAL PRIMARY KEY,
  user_id      INTEGER REFERENCES users(id) ON DELETE CASCADE,
  game_id      INTEGER NOT NULL,
  game_name    TEXT NOT NULL,
  game_image   TEXT,  -- legado: não é mais usado pelo código (usa cover_url)
  rating       INTEGER NOT NULL,
  review       TEXT,  -- legado: substituída por review_text
  created_at   TIMESTAMP DEFAULT NOW(),
  cover_url    TEXT,
  review_text  TEXT
);

CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews (user_id);


-- -------------------------------------------------------------
-- Códigos enviados por e-mail (verificação e recuperação de senha)
-- -------------------------------------------------------------
-- O código fica guardado só como hash (bcrypt).
CREATE TABLE IF NOT EXISTS email_codes (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose     TEXT NOT NULL,  -- 'verify' | 'reset'
  code_hash   TEXT NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0,
  expires_at  TIMESTAMP NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS email_codes_user_purpose_idx ON email_codes (user_id, purpose);
