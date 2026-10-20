# Análise de Requisitos

## Objetivo

Documentar os requisitos funcionais e não funcionais do projeto Gamer Letterbox / Playboxed, garantindo clareza para o desenvolvimento e validação de funcionalidades.

## Stakeholders

- Usuário final: jogadores que querem descobrir, avaliar e gerenciar sua biblioteca de jogos.
- Desenvolvedores: equipe responsável pelo app Flutter e backend Node.js.
- Administrador do sistema: responsável pela infraestrutura de backend, banco de dados e integrações.
- Serviço externo: Supabase para autenticação e PostgreSQL para persistência de dados.

## Requisitos Funcionais

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

## Requisitos Não Funcionais

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

## Interfaces Externas

- Supabase: autenticação e gerenciamento de usuários (opcional, conforme implantação).
- PostgreSQL: persistência de usuários, bibliotecas e reviews.
- IGDB / Twitch API: fonte de metadados de jogos e capas.

## Restrições e Dependências

- Flutter como framework principal do app móvel.
- Node.js e Express no backend.
- PostgreSQL como banco de dados relacional.
- Integração com Supabase para autenticação e storage de usuário.

## Histórias de Usuário

- HU001: Como jogador, quero me cadastrar e fazer login para acessar minha biblioteca.
- HU002: Como jogador, quero ver os jogos em destaque para descobrir novos títulos.
- HU003: Como jogador, quero pesquisar jogos para encontrar títulos específicos.
- HU004: Como jogador, quero ver detalhes de um jogo para aprender mais antes de adicioná-lo à biblioteca.
- HU005: Como jogador, quero escrever avaliações para compartilhar minha experiência.
- HU006: Como jogador, quero ativar alto contraste para melhorar a leitura.
- HU007: Como jogador, quero ajustar o tamanho da fonte para maior conforto.

## Critérios de Aceitação

- O app deve permitir login e cadastro com validação de formulário.
- O app deve exibir listas de jogos e permitir pesquisa funcional.
- O app deve permitir adicionar jogos à biblioteca e ver o status de cada jogo.
- O app deve exibir e publicar reviews de jogos.
- O app deve aplicar o tema de alto contraste e a escala de fonte nas telas.
- O app deve navegar entre as principais seções sem travar.
