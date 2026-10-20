---
title: "Gamer Letterbox / Playboxed — Documentação Consolidada"
---

# Gamer Letterbox / Playboxed — Documentação Consolidada

## Sumário

- [Introdução](#introdução)
- [Requisitos](#requisitos)
  - [Objetivo](#objetivo)
  - [Stakeholders](#stakeholders)
  - [Requisitos Funcionais](#requisitos-funcionais)
  - [Requisitos Não Funcionais](#requisitos-não-funcionais)
  - [Interfaces Externas](#interfaces-externas)
  - [Restrições e Dependências](#restrições-e-dependências)
  - [Histórias de Usuário](#histórias-de-usuário)
  - [Critérios de Aceitação](#critérios-de-aceitação)
- [Arquitetura do Projeto](#arquitetura-do-projeto)
  - [Visão Geral](#visão-geral)
  - [Camadas do App Flutter](#camadas-do-app-flutter)
    - [Entrada](#entrada)
    - [Serviços](#serviços)
    - [Repositórios](#repositórios)
    - [Telas](#telas)
    - [Widgets Reutilizáveis](#widgets-reutilizáveis)
  - [Backend](#backend)
    - [Servidor](#servidor)
    - [Rotas Principais](#rotas-principais)
    - [Autenticação](#autenticação)
    - [Integração com IGDB](#integração-com-igdb)
  - [Fluxo de Tema Dinâmico](#fluxo-de-tema-dinâmico)
  - [Padrões de Design](#padrões-de-design)
  - [Boas Práticas](#boas-práticas)
- [Guia de Contribuição](#guia-de-contribuição)
  - [Fluxo de Contribuição](#fluxo-de-contribuição)
  - [Estilo de Código](#estilo-de-código)
  - [Temas e Acessibilidade](#temas-e-acessibilidade)
  - [Testes e Verificação](#testes-e-verificação)
  - [Arquitetura da Aplicação](#arquitetura-da-aplicação)
  - [Backend](#backend-1)
  - [Qualidade de Código](#qualidade-de-código)
  - [Pull Requests](#pull-requests)
- [Como Rodar](#como-rodar)
- [Referências](#referências)

## Introdução

Esta documentação consolidada reúne os requisitos, a arquitetura, as diretrizes de contribuição e o resumo do projeto Gamer Letterbox / Playboxed. O objetivo é fornecer um material único e organizado para apresentação, revisão e entrega.

## Resumo do Projeto

Gamer Letterbox / Playboxed é um aplicativo Flutter para descoberta, biblioteca e avaliações de jogos, com backend Node.js + PostgreSQL.

### Principais Características

- Autenticação via Supabase / backend JWT
- Tela de login e cadastro
- Feed de jogos populares e lançamentos
- Busca de jogos
- Tela de detalhes de jogo com review e biblioteca
- Biblioteca do usuário com status e progresso
- Perfil do usuário e atividade
- Configurações de alto contraste e escala de fonte
- Tela de Top Rated baseada em avaliações no backend

### Estrutura de Pastas

- `lib/main.dart` — ponto de entrada, `MaterialApp`, verificação de token e shell principal
- `lib/services/app_settings.dart` — temas e preferências persistentes de alto contraste e escala de fonte
- `lib/screens/` — telas principais do aplicativo
- `lib/widgets/` — componentes reutilizáveis de UI
- `lib/models/` — definições de modelos de dados
- `lib/repositories/` — repositórios de autenticação e biblioteca
- `backend/backend/` — API Express e integração PostgreSQL

## Requisitos

### Objetivo

Documentar os requisitos funcionais e não funcionais do projeto Gamer Letterbox / Playboxed, garantindo clareza para o desenvolvimento e validação de funcionalidades.

### Stakeholders

- Usuário final: jogadores que querem descobrir, avaliar e gerenciar sua biblioteca de jogos.
- Desenvolvedores: equipe responsável pelo app Flutter e backend Node.js.
- Administrador do sistema: responsável pela infraestrutura de backend, banco de dados e integrações.
- Serviço externo: Supabase para autenticação e PostgreSQL para persistência de dados.

### Requisitos Funcionais

1. RF001 - Autenticação de Usuário
   - O sistema deve permitir login e cadastro de usuários.
   - O sistema deve autenticar usuários via Supabase ou backend JWT.

2. RF002 - Visualização de Jogos
   - O app deve exibir listas de jogos populares, lançamentos e recomendados.
   - O app deve permitir buscar jogos por nome.

3. RF003 - Tela de Detalhes de Jogo
   - O app deve exibir informações detalhadas do jogo, incluindo capa, descrição e avaliações.
   - O app deve mostrar reviews de outros usuários e permitir que o usuário adicione seu próprio review.

4. RF004 - Biblioteca de Usuário
   - O app deve permitir que o usuário adicione jogos à sua biblioteca.
   - O app deve permitir marcar o status do jogo (por exemplo: jogando, concluído, desejando).

5. RF005 - Avaliações e Reviews
   - O app deve permitir que o usuário escreva e publique avaliações de jogos.
   - O app deve permitir visualizar avaliações existentes de outros usuários.

6. RF006 - Configurações de Acessibilidade
   - O app deve oferecer opção de alto contraste.
   - O app deve permitir ajuste de escala de fonte.

7. RF007 - Navegação e Interface
   - O app deve fornecer navegação por abas entre as principais telas.
   - O app deve exibir feedback visual para ações importantes.

### Requisitos Não Funcionais

1. RNF001 - Performance
   - O app deve carregar telas principais em menos de 2 segundos em conexões móveis razoáveis.

2. RNF002 - Usabilidade
   - A interface deve ser responsiva e acessível, com suporte a temas de alto contraste e ajuste de fonte.

3. RNF003 - Segurança
   - A autenticação deve proteger endpoints sensíveis usando tokens JWT.
   - Dados do usuário devem ser armazenados de forma segura no backend.

4. RNF004 - Confiabilidade
   - O sistema deve tratar erros de rede e exibir mensagens claras ao usuário.

5. RNF005 - Escalabilidade
   - O backend deve estar preparado para aumentar a base de usuários, com separação de responsabilidades entre API e banco de dados.

### Interfaces Externas

- Supabase: autenticação e gerenciamento de usuários (opcional, conforme implantação).
- PostgreSQL: persistência de usuários, bibliotecas e reviews.
- IGDB / Twitch API: fonte de metadados de jogos e capas.

### Restrições e Dependências

- Flutter como framework principal do app móvel.
- Node.js e Express no backend.
- PostgreSQL como banco de dados relacional.
- Integração com Supabase para autenticação e storage de usuário.

### Histórias de Usuário

- HU001: Como jogador, quero me cadastrar e fazer login para acessar minha biblioteca.
- HU002: Como jogador, quero ver os jogos em destaque para descobrir novos títulos.
- HU003: Como jogador, quero pesquisar jogos para encontrar títulos específicos.
- HU004: Como jogador, quero ver detalhes de um jogo para aprender mais antes de adicioná-lo à biblioteca.
- HU005: Como jogador, quero escrever avaliações para compartilhar minha experiência.
- HU006: Como jogador, quero ativar alto contraste para melhorar a leitura.
- HU007: Como jogador, quero ajustar o tamanho da fonte para maior conforto.

### Critérios de Aceitação

- O app deve permitir login e cadastro com validação de formulário.
- O app deve exibir listas de jogos e permitir pesquisa funcional.
- O app deve permitir adicionar jogos à biblioteca e ver o status de cada jogo.
- O app deve exibir e publicar reviews de jogos.
- O app deve aplicar o tema de alto contraste e a escala de fonte nas telas.
- O app deve navegar entre as principais seções sem travar.

## Arquitetura do Projeto

### Visão Geral

O projeto é composto por:

- App Flutter (mobile)
- Backend Node.js/Express com PostgreSQL

O app usa um padrão simples de camada para separar interface, lógica de estado e acesso a dados.

### Camadas do App Flutter

#### Entrada

- `lib/main.dart`
  - Inicializa `AppSettings`
  - Configura tema global do Material
  - Define o fluxo de autenticação inicial
  - Monta o `AppShell` com navegação por abas

#### Serviços

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

#### Repositórios

- `lib/repositories/auth_repository.dart`
  - Encapsula lógica de autenticação Supabase
- `lib/repositories/library_repository.dart`
  - Encapsula operações de biblioteca no Supabase

#### Telas

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

#### Widgets Reutilizáveis

- `lib/widgets/game_details_header.dart` — cabeçalho da tela de detalhes
- `lib/widgets/game_grid_card.dart` — card de jogo para grid
- `lib/widgets/game_horizontal_card.dart` — card de jogo horizontal
- `lib/widgets/hero_banner.dart` — banner de destaque
- `lib/widgets/section_title.dart` — título de seção estilizado
- `lib/widgets/review_card.dart` / `review_card_large.dart` — cartões de avaliação
- `lib/widgets/navigation/bottom_navbar.dart` — navegação inferior

### Backend

Localizado em `backend/backend/`.

#### Servidor

- `server.js`
  - Inicializa Express, CORS e body parser
  - Configura conexão PostgreSQL via `pg`
  - Define middleware de autenticação JWT
  - Expõe rotas de usuário, biblioteca, reviews e jogos

#### Rotas Principais

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

#### Autenticação

- JWT via `jsonwebtoken`
- Middleware `authMiddleware`
- Cabeçalho `Authorization: Bearer <token>`

#### Integração com IGDB

- O backend faz chamadas à API IGDB usando `axios` para:
  - dados de jogos populares
  - lançamentos recentes
  - busca de jogos

### Fluxo de Tema Dinâmico

1. `AppSettings.load()` é chamado antes de `runApp`
2. `MyApp` e telas usam `ListenableBuilder` para reagir a mudanças
3. Preferências persistem em `SharedPreferences`
4. Alteração de `highContrast` e `fontScale` atualiza a UI imediatamente

### Padrões de Design

- Singleton com `AppSettings()` para estado compartilhado
- `ListenableBuilder` para reatividade de tema
- `IndexedStack` para manter estado entre abas
- Separação entre UI (`screens/widgets`) e dados/serviços (`services/repositories`)

### Boas Práticas

- Extraia estilos e componentes comuns em widgets reutilizáveis
- Evite cores codificadas; prefira `AppSettings` ou `ThemeData`
- Mantenha o backend independente de UI
- Documente endpoints e variáveis de ambiente ao expandir o backend

## Guia de Contribuição

### Fluxo de Contribuição

1. Faça um fork do repositório, ou crie uma branch no repositório principal se você tiver acesso.
2. Crie uma branch de feature/desenvolvimento descrevendo a alteração:
   - `feature/tema-alto-contraste`
   - `fix/game-details-theme`
3. Faça commits pequenos e atômicos.
4. Atualize a documentação quando necessário.
5. Envie um Pull Request com descrição clara das mudanças e as telas/funcionalidades afetadas.

### Estilo de Código

- Use indentação consistente de 2 espaços em Dart/Flutter.
- Prefira `const` quando possível.
- Evite duplicação de lógica de tema; use `AppSettings` para cores e preferências.
- Decore o widget com `ListenableBuilder` ou `ValueListenableBuilder` quando precisar de atualizações reativas.
- Mantenha os widgets simples e extraia componentes reutilizáveis em `lib/widgets/`.

### Temas e Acessibilidade

O projeto fornece suporte a alto contraste e escala de fonte via `AppSettings`:

- `lib/services/app_settings.dart` — singleton com `ChangeNotifier`
- Valores usados:
  - `bgColor`
  - `cardColor`
  - `textColor`
  - `mutedColor`
  - `borderColor`
  - `accentColor`
  - `accentTextColor`
- Use `SharedPreferences` para persistir as preferências do usuário.
- Evite cores codificadas no código sempre que possível.

### Testes e Verificação

- Execute `flutter pub get` para instalar dependências.
- Use `flutter analyze` para verificar problemas de análise.
- Rode `flutter test` se houver testes automatizados disponíveis.
- No backend, use `npm test` quando houver testes ou execute o servidor local para validação funcional.

### Arquitetura da Aplicação

O app está organizado em camadas claras:

- `lib/main.dart` — ponto de entrada e configuração de tema global
- `lib/screens/` — telas da aplicação
- `lib/widgets/` — componentes de interface reutilizáveis
- `lib/services/` — serviços e integração com API/estado global
- `lib/repositories/` — acesso a dados/autenticação

### Backend

O backend local está em `backend/backend/` e inclui:

- `server.js` — servidor Express com rotas para auth, reviews, biblioteca e jogos
- `package.json` — dependências Node
- `.env` — variáveis de ambiente para conexão com banco e IGDB

### Qualidade de Código

- Mantenha os arquivos de UI legíveis e separe lógica de apresentação da lógica de dados.
- Prefira arquiteturas baseadas em serviços e repositórios para evitar acoplamento.
- Documente novas rotas ou endpoints conforme adiciona funcionalidades.

### Pull Requests

- Mantenha a descrição curta e objetiva.
- Liste o que foi alterado e por quê.
- Referencie tickets ou issues se houver.
- Informe se a alteração requer mudanças em ambientes ou configurações externas.

## Como Rodar

### Pré-requisitos

- Flutter instalado
- Node.js instalado
- PostgreSQL disponível
- Conta e credenciais Supabase configuradas, se usadas

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

## Referências

- `README.md`
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `REQUIREMENTS.md`
