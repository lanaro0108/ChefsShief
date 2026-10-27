# Roteiro de demonstração e critérios

## Apresentação sugerida

1. Explique o problema da GourmetGo: descobrir receitas e manter um caderno particular com ingredientes e passos estruturados.
2. Crie uma conta pela interface. Saia e entre novamente para demonstrar Firebase Auth.
3. Pesquise `Arrabiata`, abra uma receita e mostre imagem, categoria, ingredientes e preparo.
4. Marque alguns ingredientes e salve no caderno.
5. Abra **Meu caderno** e use **Dar meu toque** para editar título, ingrediente, passo e observações.
6. Abra a mesma conta em outra sessão e demonstre a atualização por snapshots.
7. Mostre o documento no Firestore: `ingredients` e `instructions` como arrays, metadados como strings e datas como timestamps.
8. Entre com outra conta: o caderno deve estar vazio. Mostre os testes que tentam acessar o UID alheio.
9. Remova uma receita com confirmação e mostre a lista atualizada.
10. Busque um nome inexistente e desligue a conexão para demonstrar o tratamento de falhas.

## Matriz de atendimento

| Critério | Implementação / evidência |
| --- | --- |
| Flutter responsivo | Auth, descoberta, caderno, detalhes e editor; celular e desktop |
| API externa | Cliente HTTPS TheMealDB e busca por nome |
| Login e registro | Firebase Auth Email/Password, nome e mensagens traduzidas |
| Create | Snapshot completo em transação, ID determinístico por usuário |
| Read | Stream por UID ordenado por `savedAt`; detalhes completos |
| Update | Editor de título, arrays e observações, com validação e confirmação de descarte |
| Delete | Confirmação e transação para remover do caderno |
| Dados complexos | Arrays de strings para ingredientes e passos, validados no servidor |
| Privacidade | Regras por UID e negação padrão; testes anônimos e entre contas |
| Storage | Sem upload no escopo; regras negam acesso por padrão |
| Arquitetura | Domínio, dados e apresentação; dependências por construtor |
| Estado | Auth/Firestore streams; busca com proteção de concorrência |
| Robustez | Timeout de API, retry, estados vazios, fallback de imagem e erros de formulário |
| Qualidade | Análise estática, formatação, widgets e testes reais nos emuladores |
| Organização | README, roteiro, validação, scripts e CI |

## Decisões para explicar

- Receita salva é uma cópia, permitindo personalização sem depender de mudanças na API.
- O ID vem da API e fica abaixo do UID: não duplica em um caderno e pode existir em cadernos diferentes.
- Regras verificam caminho e formato: validar formulários não protege o banco contra clientes maliciosos.
- Cloud Functions e upload não são necessários neste cenário.
- Emuladores validam o fluxo local. O backend na nuvem exige criar o projeto e publicar as regras conforme o README.

## Competências socioemocionais

Planejamento e resolução de problemas podem ser demonstrados pelas decisões, testes de limites e organização. O histórico Git deve registrar trabalho real da equipe. Esta entrega não inventa prazos, participação individual, feedback de colegas ou um histórico de commits que não ocorreu.
