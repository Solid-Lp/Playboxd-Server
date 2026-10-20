# Gamer Letterbox / Playboxed Architecture

Este documento descreve os principais blocos de arquitetura do aplicativo Flutter e do backend.

## Visão Geral

O projeto é composto por:

- App Flutter (mobile)
- Backend Node.js/Express com PostgreSQL

O app usa um padrão simples de camada para separar interface, lógica de estado e acesso a dados.

## Camadas do App Flutter

### 1. Entry Point

- `lib/main.dart`
  - Inicializa `AppSettings`
  - Configura tema global do Material
  - Define o fluxo de autenticação inicial
  - Monta o `AppShell` com navegação por abas

### 2. Serviços

- `lib/services/app_settings.dart`
  - Singleton com `ChangeNotifier`
  - Gerencia preferências de alto contraste e escala de fonte
  - Persiste em `SharedPreferences`
- `lib/services/api_service.dart`
  - Define `baseUrl` do backend local
- `lib/services/supabase_service.dart`
  - Fornece instância do cliente Supabase
- `lib/services/igdb_service.dart`
  - Pode ser usado para integração futura com IGDB

### 3. Repositórios

- `lib/repositories/auth_repository.dart`
  - Encapsula lógica de autenticação Supabase
- `lib/repositories/library_repository.dart`
  - Encapsula operações de biblioteca no Supabase

### 4. Telas

- `lib/screens/home_screen.dart` — tela principal e feed de jogos
- `lib/screens/discover_screen.dart` — exploração de jogos
- `lib/screens/game_details_screen.dart` — detalhes e avaliações de jogo
- `lib/screens/library_screen.dart` — biblioteca do usuário
- `lib/screens/profile_screen.dart` — perfil e estatísticas
- `lib/screens/settings_screen.dart` — configurações de tema e acessibilidade
- `lib/screens/top_rated_screen.dart` — jogos melhor avaliados
- `lib/screens/write_review_screen.dart` — formulário de review
- `lib/screens/login_screen.dart` — autenticação de login
- `lib/screens/signup_screen.dart` — cadastro de usuário
- `lib/screens/edit_profile_screen.dart` — edição de perfil
- `lib/screens/reviews_screen.dart` — lista de reviews
- `lib/screens/search_screen.dart` — busca de jogos

### 5. Widgets Reutilizáveis

- `lib/widgets/game_details_header.dart` — cabeçalho da tela de detalhes
- `lib/widgets/game_grid_card.dart` — card de jogo para grid
- `lib/widgets/game_horizontal_card.dart` — card de jogo horizontal
- `lib/widgets/hero_banner.dart` — banner de destaque
- `lib/widgets/section_title.dart` — título de seção estilizado
- `lib/widgets/review_card.dart` / `review_card_large.dart` — cartões de avaliação
- `lib/widgets/navigation/bottom_navbar.dart` — navegação inferior

## Backend

Localizado em `backend/backend/`.

### 1. Server

- `server.js`
  - Inicializa Express, CORS e body parser
  - Configura conexão PostgreSQL via `pg`
  - Define middleware de autenticação JWT
  - Expõe rotas de usuário, biblioteca, reviews e jogos

### 2. Rotas Principais

- `POST /register`
- `POST /login`
- `GET /popular-games`
- `GET /new-releases`
- `GET /search-games`
- `GET /library`
- `POST /library`
- `PATCH /library/:game_id`
- `DELETE /library/:game_id`
- `GET /reviews/popular`
- `GET /reviews/:game_id`
- `POST /reviews`
- `GET /top-rated`
- `GET /activity`
- `GET /profile/stats`

### 3. Autenticação

- JWT via `jsonwebtoken`
- Middleware `authMiddleware`
- Cabeçalho `Authorization: Bearer <token>`

### 4. Integração com IGDB

- O backend faz chamadas à API IGDB usando `axios` para:
  - dados de jogos populares
  - lançamentos recentes
  - busca de jogos

## Fluxo de Tema Dinâmico

1. `AppSettings.load()` é chamado antes de `runApp`
2. `MyApp` e telas usam `ListenableBuilder` para reagir a mudanças
3. Preferências persistem em `SharedPreferences`
4. Alteração de `highContrast` e `fontScale` atualiza a UI imediatamente

## Padrões de Design

- Singleton com `AppSettings()` para estado compartilhado
- `ListenableBuilder` para reatividade de tema
- `IndexedStack` para manter estado entre abas
- Separação entre UI (`screens/widgets`) e dados/serviços (`services/repositories`)

## Boas Práticas

- Extraia estilos e componentes comuns em widgets reutilizáveis
- Evite cores codificadas; prefira `AppSettings` ou `ThemeData`
- Mantenha o backend independente de UI
- Documente endpoints e variáveis de ambiente ao expandir o backend
