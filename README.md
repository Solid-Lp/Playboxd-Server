# Gamer Letterbox / Playboxed

Aplicativo Flutter para descoberta, biblioteca e avaliações de jogos, com backend Node.js + PostgreSQL.

## Sumário

- [Visão Geral](#visão-geral)
- [Principais Recursos](#principais-recursos)
- [Arquitetura do Projeto](#arquitetura-do-projeto)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Como Rodar](#como-rodar)
- [Documentação Adicional](#documentação-adicional)

## Visão Geral

Este projeto combina um app móvel Flutter com um backend Node.js que fornece autenticação, dados de jogos, biblioteca do usuário e avaliações. O app oferece navegação com abas, temas dinâmicos e suporte a alto contraste via `AppSettings`.

## Principais Recursos

- Autenticação via Supabase / backend JWT
- Tela de login e cadastro
- Feed de jogos populares e lançamentos
- Busca de jogos
- Tela de detalhes de jogo com review e biblioteca
- Biblioteca do usuário com status e progresso
- Perfil do usuário e atividade
- Configurações de alto contraste e escala de fonte
- Tela de Top Rated baseada em avaliações no backend

## Arquitetura do Projeto

O app é dividido em camadas:

- `lib/main.dart` — ponto de entrada, `MaterialApp`, verificação de token e shell principal
- `lib/services/app_settings.dart` — temas e preferências persistentes de alto contraste e escala de fonte
- `lib/screens/` — telas principais do aplicativo
- `lib/widgets/` — componentes reutilizáveis de UI
- `lib/models/` — definições de modelos de dados
- `lib/repositories/` — repositórios de autenticação e biblioteca
- `backend/backend/` — API Express e integração PostgreSQL

## Estrutura de Pastas

- `lib/screens/`
  - `home_screen.dart`
  - `discover_screen.dart`
  - `game_details_screen.dart`
  - `library_screen.dart`
  - `login_screen.dart`
  - `signup_screen.dart`
  - `search_screen.dart`
  - `settings_screen.dart`
  - `top_rated_screen.dart`
  - `write_review_screen.dart`
  - `profile_screen.dart`
  - `edit_profile_screen.dart`
  - `reviews_screen.dart`
- `lib/widgets/`
  - `game_details_header.dart`
  - `game_grid_card.dart`
  - `game_horizontal_card.dart`
  - `hero_banner.dart`
  - `section_title.dart`
  - `review_card.dart`
  - `review_card_large.dart`
  - `navigation/bottom_navbar.dart`
- `lib/services/`
  - `app_settings.dart`
  - `api_service.dart`
  - `supabase_service.dart`
  - `igdb_service.dart`
- `lib/models/`
  - `game.dart`
  - `user.dart`
- `lib/repositories/`
  - `auth_repository.dart`
  - `library_repository.dart`
- `backend/backend/`
  - `server.js`
  - `package.json`
  - `.env`

## Como Rodar

### Pré-requisitos

- Flutter instalado
- Node.js instalado
- PostgreSQL disponível
- Conta e credenciais Supabase configuradas, se usadas

### Documentação Adicional

- `CONTRIBUTING.md` — guia de contribuição para o projeto
- `ARCHITECTURE.md` — descrição da arquitetura do app e backend
- `REQUIREMENTS.md` — análise de requisitos funcionais e não funcionais

### Backend

1. Acesse o diretório do backend:
   ```bash
   cd backend/backend
   ```
2. Instale dependências:
   ```bash
   npm install
   ```
3. Crie um arquivo `.env` com as variáveis:
   ```env
   DATABASE_URL=postgres://<user>:<password>@<host>:<port>/<database>
   JWT_SECRET=sua_chave_secreta
   TWITCH_CLIENT_ID=<twitch_client_id>
   TWITCH_ACCESS_TOKEN=<twitch_access_token>
   PORT=3000
   ```
4. Inicie o servidor:
   ```bash
   node server.js
   ```

### App Flutter

1. No diretório raiz do projeto:
   ```bash
   cd c:\Users\Gabriel\Gamer-Letterbox
   ```
2. Instale dependências:
   ```bash
   flutter pub get
   ```
3. Execute o app:
   ```bash
   flutter run
   ```

## Configuração do Backend

O backend usa Express, PostgreSQL e JWT para autenticação. A API está configurada para rodar na porta `3000` por padrão.

### Variáveis de ambiente necessárias

- `DATABASE_URL` — URL de conexão PostgreSQL
- `JWT_SECRET` — chave secreta para tokens JWT
- `TWITCH_CLIENT_ID` — client ID Twitch para IGDB
- `TWITCH_ACCESS_TOKEN` — token de acesso Twitch para IGDB
- `PORT` — porta de execução do servidor

## Endpoints da API

- `GET /` — status básico da API
- `POST /register` — registro de usuário
- `POST /login` — login de usuário
- `GET /popular-games` — jogos populares via IGDB
- `GET /new-releases` — lançamentos recentes via IGDB
- `GET /search-games?q=<termo>` — busca de jogos via IGDB
- `GET /library` — lista de jogos na biblioteca do usuário (autenticado)
- `POST /library` — adiciona / atualiza jogo na biblioteca (autenticado)
- `PATCH /library/:game_id` — atualiza status/progresso da biblioteca (autenticado)
- `DELETE /library/:game_id` — remove jogo da biblioteca (autenticado)
- `GET /reviews/popular` — reviews populares
- `POST /reviews` — publica review no banco (autenticado)
- `GET /reviews/:game_id` — reviews por jogo
- `GET /top-rated` — jogos mais bem avaliados pelo banco
- `GET /activity` — feed de atividade do usuário (autenticado)
- `GET /profile/stats` — estatísticas do perfil do usuário (autenticado)

## Navegação e Telas

### `main.dart`

- Carrega `AppSettings` antes de iniciar o app
- Exibe `LoginScreen` ou `AppShell` com base no token salvo
- Configura tema global via `ThemeData` e `ColorScheme`

### `AppShell`

- Contém `IndexedStack` com as abas principais:
  - `MainScreen`
  - `LibraryScreen`
  - `ProfileScreen`
- Atualiza biblioteca/perfil ao alternar abas

### Telas principais

- `home_screen.dart` — tela inicial com seções de jogos e reviews
- `discover_screen.dart` — exploração de jogos
- `game_details_screen.dart` — detalhes do jogo, reviews, biblioteca e notas
- `library_screen.dart` — biblioteca do usuário
- `search_screen.dart` — busca de jogos
- `profile_screen.dart` — perfil do usuário
- `settings_screen.dart` — configurações de alto contraste e tamanho de fonte
- `top_rated_screen.dart` — lista de jogos com melhores avaliações
- `write_review_screen.dart` — formulário para publicar review
- `login_screen.dart` e `signup_screen.dart` — fluxo de autenticação
- `edit_profile_screen.dart` — edição de perfil
- `reviews_screen.dart` — lista de reviews da comunidade

## Temas e Acessibilidade

A classe `AppSettings` persiste preferências de usuário usando `SharedPreferences`:

- `highContrast` — altera as cores de fundo, cards, texto e acentos
- `fontScale` — ajusta a escala de fonte usada nos previews e textos dinâmicos

Essa configuração é usada por `ListenableBuilder` em `main.dart` e em telas individuais para permitir alterações de tema em tempo real.

### Cores dinâmicas do tema

- `bgColor` — fundo da aplicação
- `cardColor` — cor de cartões e seções
- `textColor` — cor principal do texto
- `mutedColor` — texto secundário
- `borderColor` — bordas e divisórias
- `accentColor` — cor de destaque
- `accentTextColor` — texto sobre elementos de destaque

## Serviços e Repositórios

### `lib/services/app_settings.dart`

- Singleton `AppSettings` para estado global de tema
- Notifica ouvintes quando preferências mudam
- Persiste alto contraste e escala de fonte

### `lib/services/api_service.dart`

- Define `baseUrl` do backend local

### `lib/services/supabase_service.dart`

- Expõe `Supabase.instance.client` para autenticação e dados no Supabase

### `lib/repositories/auth_repository.dart`

- Método de cadastro, login e logout
- Acessa usuário/sessão do Supabase

### `lib/repositories/library_repository.dart`

- Adiciona e consulta jogos do usuário no Supabase

## Dependências principais

- `flutter`
- `supabase_flutter`
- `google_fonts`
- `http`
- `image_picker`
- `shared_preferences`
- `cached_network_image`
- `url_launcher`
- `express`
- `pg`
- `jsonwebtoken`
- `bcrypt`
- `dotenv`
- `axios`
- `cors`

## Notas

- O backend local se conecta ao IGDB via Twitch usando `TWITCH_CLIENT_ID` e `TWITCH_ACCESS_TOKEN`.
- A API local também oferece rotas para biblioteca, reviews e estatísticas do usuário.
- O projeto tem suporte para alto contraste e mudanças de escala de fonte, permitindo testes de acessibilidade.

---

## Contato

Para estender o projeto, siga a estrutura de pastas e mantenha separação entre UI (`screens/widgets`) e lógica de dados (`services/repositories`).
