# Validação e limites da entrega

## Verificado neste ambiente

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

Capturas reais do fluxo estão em [screenshots/](screenshots/). O APK local fica em `build/app/outputs/flutter-apk/app-debug.apk`; arquivos gerados, caches e logs não são versionados.

## O que ainda depende de configuração externa

- **Projeto Firebase de produção:** o usuário informou que ainda não possui um. Nenhum projeto foi criado ou publicado. Siga o README para habilitar Email/Password, criar Firestore, registrar os apps e publicar as regras.
- **Aplicação na nuvem:** não houve deploy em Firebase Hosting ou distribuição em loja. O build local usa o projeto de demonstração dos emuladores.
- **Android em dispositivo:** o APK foi compilado; não foi executado em um telefone ou emulador do sistema Android neste ambiente. O endereço `10.0.2.2` foi configurado para desenvolvimento com um emulador Android na mesma máquina dos serviços Firebase.
- **iOS:** não foi incluído nem validado; requer um ambiente macOS/Xcode.
- **GitHub e CI:** o workflow está em `.github/workflows/ci.yml`. Os resultados locais não comprovam execução remota da CI; confira a aba Actions do repositório para verificar o resultado de cada push.
- **Configuração do ambiente:** instruções salvas no rascunho não significam que houve publicação de um snapshot ou validação em uma nova tarefa.

Storage e Cloud Functions não são necessários para este cenário. Não houve teste de upload: não existe funcionalidade de upload e as regras de Storage negam todo acesso por padrão.

## Ferramentas preparadas

Flutter 3.38.10 / Dart 3.10.9, Node 24, JDK Temurin 21 completo, Android SDK 36, build tools e NDK exigidos pelo template, além de Firebase CLI e Chromium. Os SDKs e caches de nuvem ficam fora do checkout e são ativados por `scripts/env.sh`. O uso do proxy preserva a verificação TLS; o Java usa um truststore local com as CAs do sistema e a CA pública fornecida pelo ambiente.
