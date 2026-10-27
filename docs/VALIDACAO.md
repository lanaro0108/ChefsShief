# Validação e limites da entrega

## Atualização de interface e tradução — 27/10/2026

- Fundo vetorial de papel marfim e ervas, títulos Lora locais, destaque de receita responsivo e painel pautado para ingredientes com contador de itens separados.
- Busca por categorias reais em português, carregamento completo de resumos ao abrir/salvar e cartões em blocos de 12.
- Tradução de título, medidas, ingredientes e preparo, cache por conteúdo, consulta ao original e preservação de edições e notas pessoais. As origens atuais do catálogo têm rótulos locais.
- `flutter analyze`: sem apontamentos. `flutter test --coverage`: **28 testes aprovados**. Testes oficiais de Auth/Firestore: **9 aprovados**. Web release compilada com recursos gráficos e fontes locais.
- O teste de navegador validou cadastro, categorias, busca, detalhes em português, consulta ao original, salvamento, edição, exclusão, logout e login em desktop e celular. As capturas ficam em `docs/screenshots/`.

O provedor de tradução online é simulado nos testes para evitar dependência de cota e disponibilidade. Há também uma receita completa com tradução revisada por conteúdo, coberta por fixture real do TheMealDB. API, SDK Firebase e emuladores continuam reais. O domínio do MyMemory não está liberado para acesso ao vivo neste ambiente; o app trata indisponibilidade/cota mantendo o original e a opção de tentar novamente. Nenhuma configuração de produção foi necessária para os testes. O APK Android não foi recompilado nesta alteração de interface e conteúdo.

## Histórico da validação original

| Verificação | Resultado |
| --- | --- |
| `dart format` | Código Dart formatado |
| `flutter analyze` | Nenhum problema encontrado |
| `flutter test --coverage` | **13 testes passaram**, sem testes ignorados |
| `npm run test:rules` | **9 testes passaram**, usando Auth e Firestore oficiais nos emuladores |
| TheMealDB | Busca HTTPS real por `Arrabiata` retornou `Spicy Arrabiata Penne` |
| Build web release | Compilou com recursos gráficos e fontes locais |
| Navegador Chromium | Fluxo completo em desktop e viewport de celular, sem exceções não tratadas |
| Build Android | APK de desenvolvimento **ARM64** compilado com o modo de emuladores |
| Instalação | Script de instalação reexecutado com lockfiles preservados |

O teste de navegador criou uma conta temporária, buscou uma receita real, exibiu detalhes, salvou no Firestore, editou título, ingrediente, passo e observações, abriu o caderno no celular, cancelou uma exclusão, confirmou a remoção, saiu e entrou novamente. Os testes de backend também verificaram recuperação de senha, snapshots em tempo real e tentativas de acesso entre contas.

As regras foram testadas com todos os **40 itens** em ambos os arrays, inclusive ingredientes de 300 caracteres e passos de 5.000 caracteres, sem exceder o limite de avaliação do Firestore. Tipos incorretos, campos extras, datas adulteradas, URLs não permitidas e caracteres de controle usados como separadores foram rejeitados.

Um teste de regressão verifica que campos opcionais Firebase não configurados são enviados como ausentes nas opções do SDK. O caso reproduziu o domínio vazio que fazia o Firebase Auth Android lançar `Given String is empty or null` ao cadastrar um usuário.

A identidade visual foi atualizada com Poppins local, a paleta vermelha solicitada e a reprodução vetorial do logo. Após essa alteração, a análise estática e os 13 testes Flutter passaram, o APK Android ARM64 foi recompilado e o fluxo completo no navegador foi repetido em desktop e celular.

Capturas reais do fluxo estão em [screenshots/](screenshots/). O APK local fica em `build/app/outputs/flutter-apk/app-debug.apk`; arquivos gerados, caches e logs não são versionados.

## O que ainda depende de configuração externa

- **Projeto Firebase de produção:** o usuário configurou o projeto `chefs-db` no próprio computador e confirmou o funcionamento do aplicativo. Os testes automatizados deste ambiente usam os emuladores; não houve acesso administrativo, alteração de configurações ou publicação de regras nesse projeto por aqui.
- **Aplicação na nuvem:** não houve deploy em Firebase Hosting ou distribuição em loja. O build local usa o projeto de demonstração dos emuladores.
- **Android em dispositivo:** o APK foi compilado; não foi executado em um telefone ou emulador do sistema Android neste ambiente. O endereço `10.0.2.2` foi configurado para desenvolvimento com um emulador Android na mesma máquina dos serviços Firebase.
- **iOS:** não foi incluído nem validado; requer um ambiente macOS/Xcode.
- **GitHub e CI:** o workflow está em `.github/workflows/ci.yml`. Os resultados locais não comprovam execução remota da CI; confira a aba Actions do repositório para verificar o resultado de cada push.
- **Configuração do ambiente:** instruções salvas no rascunho não significam que houve publicação de um snapshot ou validação em uma nova tarefa.

Storage e Cloud Functions não são necessários para este cenário. Não houve teste de upload: não existe funcionalidade de upload e as regras de Storage negam todo acesso por padrão.

## Ferramentas preparadas

Flutter 3.38.10 / Dart 3.10.9, Node 24, JDK Temurin 21 completo, Android SDK 36, build tools e NDK exigidos pelo template, além de Firebase CLI e Chromium. Os SDKs e caches de nuvem ficam fora do checkout e são ativados por `scripts/env.sh`. O uso do proxy preserva a verificação TLS; o Java usa um truststore local com as CAs do sistema e a CA pública fornecida pelo ambiente.
