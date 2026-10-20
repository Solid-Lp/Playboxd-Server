# Contributing to Gamer Letterbox / Playboxed

Obrigado por contribuir para o projeto! Este guia descreve o fluxo recomendado para colaborar, como manter a qualidade do código e como enviar alterações.

## 1. Fluxo de Contribuição

1. Faça um fork do repositório, ou crie uma branch no repositório principal se você tiver acesso.
2. Crie uma branch de feature/desenvolvimento descrevendo a alteração:
   - `feature/tema-alto-contraste`
   - `fix/game-details-theme`
3. Faça commits pequenos e atômicos.
4. Atualize a documentação quando necessário.
5. Envie um Pull Request com descrição clara das mudanças e as telas/funcionalidades afetadas.

## 2. Estilo de Código

- Use identação consistente de 2 espaços em Dart/Flutter.
- Prefira `const` quando possível.
- Evite duplicação de lógica de tema; use `AppSettings` para cores e preferências.
- Decore o widget com `ListenableBuilder` ou `ValueListenableBuilder` quando precisar de atualizações reativas.
- Mantenha os widgets simples e extraia componentes reutilizáveis em `lib/widgets/`.

## 3. Temas e Acessibilidade

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

## 4. Testes e Verificação

- Execute `flutter pub get` para instalar dependências.
- Use `flutter analyze` para verificar problemas de análise.
- Rode `flutter test` se houver testes automatizados disponíveis.
- No backend, use `npm test` quando houver testes ou execute o servidor local para validação funcional.

## 5. Arquitetura da Aplicação

O app está organizado em camadas claras:

- `lib/main.dart` — ponto de entrada e configuração de tema global
- `lib/screens/` — telas da aplicação
- `lib/widgets/` — componentes de interface reutilizáveis
- `lib/services/` — serviços e integração com API/estado global
- `lib/repositories/` — acesso a dados/autenticação

## 6. Backend

O backend local está em `backend/backend/` e inclui:

- `server.js` — servidor Express com rotas para auth, reviews, biblioteca e jogos
- `package.json` — dependências Node
- `.env` — variáveis de ambiente para conexão com banco e IGDB

## 7. Qualidade de Código

- Mantenha os arquivos de UI legíveis e separe lógica de apresentação da lógica de dados.
- Prefira arquiteturas baseadas em serviços e repositórios para evitar acoplamento.
- Documente novas rotas ou endpoints conforme adiciona funcionalidades.

## 8. Pull Requests

- Mantenha a descrição curta e objetiva.
- Liste o que foi alterado e por quê.
- Referencie tickets ou issues se houver.
- Informe se a alteração requer mudanças em ambientes ou configurações externas.
