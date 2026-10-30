<div style="text-align: justify;">

# GabGrading: Sistema de Correção de Simulados

## 🚀 Visão Geral do Projeto

O GabGrading é um sistema robusto e intuitivo projetado para o cadastro e gerenciamento eficiente de simulados. Ele permite que professores ou gestores da aplicação organizem seus simulados e os gabaritos das questões de múltipla escolha associadas de forma centralizada. A entidade central do sistema é o `Simulado`, que carrega a posse do usuário, o mecanismo de `soft delete` e é o alvo direto das buscas e filtros. A `Questão` é uma entidade dependente, existindo sempre atrelada a um simulado específico.

O sistema conta com autenticação completa, controle de posse dos dados por usuário e um mecanismo de exclusão reversível (`soft delete`) para preservar a integridade histórica dos registros.

**Foco Atual:** Gerenciamento de simulados e questões, e a correção deles: o usuário cadastra turmas e alunos, lança à mão as respostas de cada aluno em um simulado e o sistema corrige, devolvendo acertos, nota e acertos por componente curricular.
**Expansão Futura:** Ler o cartão-resposta por visão computacional, para que as respostas dos alunos entrem sem digitação. Fica como outro ciclo incremental do sistema.

---

## ✨ Funcionalidades Detalhadas

### 🔐 Autenticação e Usuários

*   **Cadastro Seguro:** O e-mail é único no sistema, e as senhas são armazenadas como hash, nunca em texto puro.
*   **Login com JWT:** O login confere o hash da senha e, se correto, emite um token JWT para autenticação.
*   **Controle de Acesso:** Todas as rotas de `Simulado` e `Questão` exigem um token válido; sem ele, a resposta é `401 Unauthorized`.
*   **Posse de Dados:** O `usuario_id` de um `Simulado` ou `Questão` é sempre extraído do token do usuário logado, impedindo a manipulação de dados de outros usuários.
*   **Soft Delete de Usuário:** A exclusão de conta é um `soft delete` (`ativo` passa para `false`). Contas inativas não conseguem logar.

### 📝 Gerenciamento de Simulados (CRUD)

*   **Criação e Edição:** `identificacao` e `data_aplicacao` são campos obrigatórios e não podem ser vazios.
*   **Controle de Posse:** Um usuário só pode listar, ver, editar ou apagar os próprios simulados; tentativas de acesso a simulados de outros usuários resultam em `404 Not Found`: o simulado de outra pessoa se comporta como se não existisse.
*   **Soft Delete de Simulado:** A exclusão de `Simulado` também é um `soft delete` (`ativo` passa para `false`), preservando o histórico e a integridade com `Questões` vinculadas.

### ❓ Gerenciamento de Questões

*   **Numeração Automática:** `numero_questao` é atribuído automaticamente pelo sistema em sequência crescente dentro do simulado.
*   **Alternativa Correta:** `alternativa_correta` é um enum fechado (A, B, C, D, E), nunca texto livre.
*   **Componente Curricular:** O campo 'componente_curricular' é obrigatório para identificação da disciplina
*   **Conteúdo Opcional:** O campo `conteudo` é opcional para a descrição da questão.
*   **Posse de Questão:** Toda `Questão` precisa apontar para um `simulado_id` que exista e pertença ao usuário logado.
*   **Visibilidade Herdada:** A visibilidade de uma `Questão` é herdada do `Simulado` ao qual ela pertence; se o `Simulado` estiver inativo, suas `Questões` não são retornadas.

### 🔍 Busca e Filtro

*   **Simulados:** A listagem de simulados aceita busca por `identificacao` e, opcionalmente, filtro por período de `data_aplicacao`.
*   **Questões:** A listagem de `Questões` de um simulado aceita busca ou ordenação por `numero_questao`.

### ✅ Validação e Respostas

*   **Validação Dupla:** A validação ocorre tanto no formulário (frontend) quanto na API (backend) antes de gravar, sem confiar apenas na validação da tela.
*   **Respostas Claras:** Toda ação de criar, editar ou apagar retorna uma resposta clara (sucesso com o registro afetado ou erro com mensagem compreensível), nunca um `500 genérico`.
*   **Listagens Padrão:** Todas as listagens (GET) filtram por padrão apenas registros com `ativo = true`.

---

## 🛠️ Entidades e Atributos Chave

### 👤 Usuário

| Atributo    | Tipo    | Restrições                               |
| :---------- | :------ | :--------------------------------------- |
| `id`        | Serial  | Chave primária, NOT NULL                 |
| `nome`      | Varchar | NOT NULL                                 |
| `email`     | Varchar | NOT NULL, único                          |
| `senha_hash`| Varchar | NOT NULL                                 |
| `ativo`     | Boolean | NOT NULL, padrão `true`                  |

### 📝 Simulado

| Atributo          | Tipo    | Restrições                               |
| :---------------- | :------ | :--------------------------------------- |
| `id`              | Serial  | Chave primária, NOT NULL                 |
| `identificacao`   | Varchar | NOT NULL                                 |
| `data_aplicacao`  | Date    | NOT NULL                                 |
| `usuario_id`      | Integer | Chave estrangeira (`Usuário`), NOT NULL  |
| `ativo`           | Boolean | NOT NULL, padrão `true`                  |

### ❓ Questão

| Atributo               | Tipo                       | Restrições                               |
| :--------------------- | :------------------------- | :--------------------------------------- |
| `id`                   | Serial                     | Chave primária, NOT NULL                 |
| `numero_questao`       | Integer                    | NOT NULL, gerado automaticamente         |
| `alternativa_correta`  | Enum (A, B, C, D, E)       | NOT NULL, conjunto fechado               |
| `conteudo`             | Text                       | Opcional                                 |
| `componente_curricular'| Enum                       | NOT NULL, conjunto fechado               |
| `simulado_id`          | Integer                    | Chave estrangeira (`Simulado`), NOT NULL |

### 🏫 Turma

| Atributo     | Tipo    | Restrições                               |
| :----------- | :------ | :--------------------------------------- |
| `id`         | Serial  | Chave primária, NOT NULL                 |
| `nome`       | Varchar | NOT NULL                                 |
| `usuario_id` | Integer | Chave estrangeira (`Usuário`), NOT NULL  |
| `ativo`      | Boolean | NOT NULL, padrão `true`                  |

### 🧑‍🎓 Aluno

| Atributo   | Tipo    | Restrições                               |
| :--------- | :------ | :--------------------------------------- |
| `id`       | Serial  | Chave primária, NOT NULL                 |
| `nome`     | Varchar | NOT NULL                                 |
| `turma_id` | Integer | Chave estrangeira (`Turma`), NOT NULL    |
| `ativo`    | Boolean | NOT NULL, padrão `true`                  |

### ✍️ Resposta

O que um aluno marcou em uma questão.

| Atributo                | Tipo                 | Restrições                                              |
| :---------------------- | :------------------- | :------------------------------------------------------ |
| `id`                    | Serial               | Chave primária, NOT NULL                                |
| `aluno_id`              | Integer              | Chave estrangeira (`Aluno`), NOT NULL                   |
| `questao_id`            | Integer              | Chave estrangeira (`Questão`), NOT NULL                 |
| `alternativa_escolhida` | Enum (A, B, C, D, E) | NOT NULL; única por par (`aluno_id`, `questao_id`)      |

---

## 🔗 Relacionamentos

*   **Usuário 1 — N Simulado:** Cada usuário pode possuir muitos simulados; cada simulado pertence a um único usuário.
*   **Simulado 1 — N Questão:** Cada simulado pode possuir muitas questões; cada questão pertence a um único simulado.
*   **Usuário 1 — N Turma:** Cada usuário cadastra as próprias turmas.
*   **Turma 1 — N Aluno:** Todo aluno pertence a uma turma; a posse do aluno é a posse da turma.
*   **Aluno 1 — N Resposta N — 1 Questão:** A resposta liga um aluno a uma questão do simulado.

---

## 🎯 Turmas, Respostas e Correção

*   `/turmas` e `/turmas/{turma_id}/alunos`: CRUD com `soft delete`, sempre restrito ao usuário logado. Turma ou aluno de outra pessoa responde `404`, como se não existisse.
*   `PUT /simulados/{simulado_id}/alunos/{aluno_id}/respostas`: lança o gabarito do aluno em lote, e **substitui** o anterior. A questão que ficar de fora fica em branco. A mesma questão duas vezes, ou uma questão que o simulado não tem, responde `422` e não grava nada (tudo ou nada).
*   `GET /simulados/{simulado_id}/alunos/{aluno_id}/respostas`: o que o aluno marcou.
*   `GET /simulados/{simulado_id}/alunos/{aluno_id}/resultado`: a correção, calculada na hora: `total_questoes`, `total_acertos`, `nota` (de 0 a 10, com duas casas, questão em branco conta como erro) e `acertos_por_componente` (RN-20).

A conta da nota mora em `respostas/correcao.py`, uma função que recebe valores e devolve a resposta, sem banco nem HTTP. O `respostas/service.py` é a fachada: confere o dono do simulado e do aluno, busca o gabarito e as respostas e chama a função.

---

## 🏗️ Decisões de Arquitetura

*   **Organização Vertical:** Estrutura de pastas vertical por entidade (ex: `simulados/`, `questoes/`, `usuarios/`), contendo seus respectivos `models.py`, `schemas.py`, `erros.py`, `repository.py`, `service.py` e `controller.py`. Não existe uma pasta `controllers/` ou `services/` única para o projeto inteiro.
*   **Import Cruzado:** Imports entre pastas de entidade são permitidos e esperados, dado que `Questão` depende de `Simulado`.
*   **Tratamento de Erros:** O arquivo `erros.py` de cada entidade contém apenas as recusas específicas daquela entidade (ex: `SimuladoNaoEncontrado`). O tradutor de exceções (`@app.exception_handler`) é único, registrado no `main.py` para a classe-mãe de erro de cada entidade.

---

## ⚙️ Tecnologias Utilizadas (Stack)

Este projeto será desenvolvido utilizando as seguintes tecnologias:

*   **Backend:** Python com FastAPI
*   **Banco de Dados:** PostgreSQL
*   **ORM:** SQLAlchemy
*   **Containerização:** Docker
*   **Controle de Versão:** Git e GitHub
*   **Gerenciamento de Dependências:** Poetry
*   **Testes (backend):** pytest

---

## 📓 Diário de Decisões (Programação III)

Este projeto será acompanhado por um "Diário de Decisões", um registro das escolhas arquiteturais e de design tomadas ao longo do desenvolvimento. Ele documentará o problema enfrentado, as alternativas consideradas, a decisão final e suas consequências, servindo como base para a defesa da arquitetura no final da disciplina.


🖊️ *Diário de decisões — Encontro 5 (Repository)*
Como já estava usando SQLAlchemy, verifiquei que parte do padrão Repository já vem embutido com a Session, então pensei em não criar essa camada separada. Mas decidi manter mesmo assim, porque duas das minhas regras de negócio não são só "buscar e salvar": a RN09 diz que excluir um simulado é soft delete (só marca ativo = False, nunca apaga de verdade) e a RN18 diz que toda listagem deve mostrar só os ativos por padrão. Se eu deixasse isso solto no service.py, a regra de negócio ficaria misturada com o jeito de mexer no banco (o .filter() e o .commit() do SQLAlchemy). Por isso criei o repository.py com métodos de nome de negócio (listar, buscar, criar, atualizar, desativar), que escondem esse "como" e devolvem sempre objetos Simulado, nunca tuplas ou dicionários crus.
Para confirmar que a separação funcionou, abri o service.py e procurei por Session e .query. Não achei nenhum: ele só recebe o db e repassa para o repositório, sem saber o que fazer com ele. A diferença para o exemplo da aula é que não tenho um dependencias.py separado; quem escolhe e entrega a conexão é o próprio Depends(get_db) do FastAPI. No meu caso concluo que o Repository valeu a pena, não por causa de uma futura troca de banco, mas porque ele já esconde o soft delete e o filtro padrão. Caso meu projeto tivessse apenas um CRUD simples, sem essas duas regras, talvez eu teria decidido não criar essa camada.


🖊️ *Diário de decisões — Encontro 7 (Strategy)*
**Antes:** Não hávia escada de If's
A regra de agrupar por intervalo e por disciplina utilizada para contar acertos por disciplina nasceu já como Strategy porque a mistura de blocos de questões com faixas contínuas (Ex: Matemática de 1 a 10, Fisica 11 a 20) e blocos com disciplinas embaralhadas dentro de uma faixa (Ciências Humanas (questões 1 a 45): Questão 1: Geografia, Questão 2: Sociologia, ..., Questão 9: Geografia) foi definida a partir do conhecimento do método Strategy.

"O que ficou mais fácil foi acrescentar um terceiro jeito de dividir área (DivisaoUnica, para simulados de uma área só) sem tocar em nada além do divisao_area.py (demonstrando no git diff --stat). Isso deixou claro o valor prático do padrão: o service.py nunca precisa saber quantos tipos de divisão existem, só que existe UM tipo que responde à pergunta certa.

O que ficou mais complicado foi a construção dos objetos. No exemplo da biblioteca, o dicionário guarda as políticas já prontas, porque nenhuma delas precisa de dado nenhum para nascer. No meu caso, DivisaoPorFaixa e DivisaoPorListaExplicita dependem dos dados daquele simulado específico (as faixas, ou o mapa), então o dicionário teve que guardar as classes, não os objetos, e uma função (divisao_para) monta o objeto certo na hora, com os dados certos. O que aproximou do padrão Factory Method, mas decisão de QUAL classe usar continua sendo Strategy, porém a MONTAGEM do objeto já não é tão simples quanto no exemplo da aula que usava dicionário."

🖊️ *Diário de decisões — Encontro 8 (Factory Method)*

Como no padrão Strategy teve uma aproximação com o Factory Method, é possível fazer a transformação completa  tirando do divisao_para a responsabilidade de escolher e montar diretamente as estratégias e criar uma fábrica específica para isso. Essa fábrica receberia os dados do simulado (o tipo de divisão, as faixas ou o mapa) e teria um método que construiria a estratégia correspondente, devolvendo um objeto pronto para uso. Assim, o código que usa a divisão não precisaria conhecer as classes concretas nem saber quais dados cada uma exige: apenas pediria à fábrica a estratégia adequada. Dessa forma, O Strategy continuaria definindo as diferentes formas de dividir a área, enquanto o Factory Method centralizaria a criação dos objetos e poderia ser estendido para novos tipos de divisão sem espalhar essa lógica pelo sistema.

🖊️ *Diário de decisões — Encontro 9 (Facade)*

O padrão de projeto vai ser atualizado assim que a parte de resposta do aluno for implementada em que a operação corrigir(aluno_id, simulado_id) encapsula toda a complexidade de buscar dados em múltiplas tabelas e fazer comparações, expondo uma interface simples ao Controller.
A lógica do padrão Facade será:
1. Receber aluno_id e simulado_id.
2. Buscar o Simulado e valida que ele existe e está ativo = true.
3. Buscar todas as Questões do Simulado.
4. Buscar todas as Respostas do aluno para aquelas Questões.
5. Comparar Questao.alternativa_correta com Resposta.alternativa_escolhida para cada questão.
6. Calcular total_acertos, total_questoes e nota (conforme fórmula a ser definida).
7. Criar um registro em Resultado com esses valores agregados.
8. Retornar o resultado ao cliente.

🖊️ *Diário de decisões — Encontro 12 (testes unitários)*

**O que estava difícil de testar**

No teste do cadastrar usuário foi preciso criar o dicionário de dados dentro de uma função e não como variável. Isso foi preciso porque a chave `senha` é removida do dicionário recebido, e o hash vai para um dicionário novo. Percebi que uma função que muda os argumentos que recebe é difícil de testar e de usar, porque, se o dicionário for usado uma segunda vez, o dado virá sem a senha.

Para testar o `gerar_hash`, que só recebe uma senha e devolve um hash, precisei criar um `conftest.py` definindo a `SECRET_KEY`. Isso foi necessário porque o `seguranca.py` exige a `SECRET_KEY` quando é importado. Percebi que o módulo estava acoplado a uma configuração que a função de hash não usa.

**O que foi fácil de testar**

Foi fácil testar os `services` porque eles são as regras de negócio: não levantam erro de protocolo (o controller faz isso), não montam consulta (o repository faz isso) e não abrem conexão (o `get_db` faz isso). Assim, só precisei chamar as funções direto, usando um banco em memória.

**O que os limites ensinaram**

Se eu tivesse testado só os casos normais, como uma questão no meio de uma faixa de questões, uma mudança no começo da faixa passaria despercebida. O teste da questão 0 foi o único que pegou o erro, porque ela está fora da faixa, logo antes do começo.

Os atritos encontrados nos testes revelaram que talvez seja interessante ler a `SECRET_KEY` dentro das funções que a usam, e não no topo do arquivo.

---

## 🚀 Como Rodar o Projeto

Para configurar e iniciar a API do GabGrading, siga os passos abaixo:

1.  **Instalar as dependências:**
    Certifique-se de ter o Poetry instalado. Na raiz do projeto, execute:
    ```bash
    poetry install
    ```

2.  **Configurar as variáveis de ambiente:**
    Crie um arquivo chamado `.env` na raiz do projeto (ao lado do `pyproject.toml`). Este arquivo **não** deve ser enviado para o Git, pois contém informações sensíveis. Preencha-o com as seguintes variáveis, adaptando os valores conforme necessário:
    ```
    DATABASE_URL=sqlite:///./gabgrading.db
    SECRET_KEY=sua_chave_secreta_aqui
    ```
    *   Para `DATABASE_URL`, você pode usar o valor padrão para SQLite ou configurar para PostgreSQL se preferir.
    *   Para `SECRET_KEY`, gere uma chave aleatória e forte.

3.  **Aplicar as migrações do banco de dados:**
    O Alembic gerencia o esquema do banco. Execute o comando para criar as tabelas `usuarios`, `simulados`, `questoes`, `turmas`, `alunos` e `respostas` (funciona também num banco vazio):
    ```bash
    poetry run alembic upgrade head
    ```
    Este comando criará o arquivo do banco de dados (se for SQLite) e todas as tabelas necessárias.

4.  **Iniciar o servidor da API:**
    ```bash
    poetry run uvicorn app.main:app --reload
    ```
    A API estará disponível em `http://127.0.0.1:8000`.

5.  **Acessar a documentação interativa:**
    Abra seu navegador e vá para `http://127.0.0.1:8000/docs` para explorar os endpoints da API e realizar testes.

---

## 🧪 Como Rodar os Testes

Os testes do backend usam o `pytest` e ficam em `backend/test/`. O `poetry install` já instala o `pytest` (grupo de desenvolvimento). Dentro da pasta `backend/`, execute:

```bash
poetry run pytest -v
```

Não é preciso criar o `.env` nem subir a API: o `test/conftest.py` define uma `SECRET_KEY` de teste e cada teste recebe um banco SQLite em memória, novo e vazio, sem encostar no `gabgrading.db`.

| Arquivo | O que testa |
| :------ | :---------- |
| `test_back.py` | A regra de divisão de área por faixa (Strategy e Factory), com os limites de cada lado e a recusa (`pytest.raises`) |
| `test_seguranca.py` | O hash da senha (RN-02) e o token JWT, incluindo o token com assinatura inválida |
| `test_usuario.py` | Cadastro, e-mail repetido (RN-01), login e conta inativa (RN-06) |
| `test_simulados.py` | Posse por dono (RN-08), soft delete (RN-09) e visibilidade (RN-18) |
| `test_questoes.py` | Numeração automática por simulado (RN-12), posse (RN-11) e visibilidade herdada (RN-13) |
| `test_correcao.py` | A conta da nota: acertos, nota de 0 a 10, questão em branco e acertos por componente (RN-20) |
| `test_turmas_alunos.py` | Posse de turmas e alunos, soft delete e o aluno que some com a turma |
| `test_respostas.py` | Lançar o gabarito em lote (substitui, tudo ou nada, recusas) e a correção ponta a ponta |

Para rodar um arquivo só: `poetry run pytest test/test_back.py -v`.

---

## 🤝 Contribuição e Histórico


O cadastro chama `POST /usuarios/` pelas mesmas camadas do login e já entra com a conta nova. Quando a API recusa (e-mail repetido, campo inválido), a frase aparece na tela.
O token fica no aparelho (`shared_preferences`, que no navegador é o `localStorage`), num repositório próprio, o `TokenRepository`. O `main` o restaura antes de abrir o app: se a API ainda o aceita, o F5 não derruba a sessão. O Sair apaga o token.

A tela de simulados chama `GET /simulados/` pelas camadas do app (tela, `SimuladoService`, `SimuladoRepository`), com o token no cabeçalho, e mostra só os simulados de quem está logado. Ela tem quatro estados: carregando, erro (com Tentar de novo), lista vazia e a lista.
Tocar num simulado abre o detalhe pela rota `/simulado`, com o id nos `arguments`: o detalhe busca o simulado na API (`GET /simulados/{id}`), para mostrar o dado de agora. Sem o id (um F5 no detalhe apaga os `arguments`), a tela mostra a lista.
Para isso o backend passou a filtrar por dono (RN-08): a listagem devolve só os simulados do usuário do token, e ver, editar ou apagar o de outra pessoa responde 404.

O app cria, edita e exclui simulados pelas camadas (tela, `SimuladoService`, `SimuladoRepository`), com o token no cabeçalho: `POST /simulados/`, `PATCH /simulados/{id}` e `DELETE /simulados/{id}`. Um formulário só (`FormularioScreen`) serve para criar e para editar, e a data pode ser digitada (dd/mm/aaaa) ou escolhida no calendário. O dono do simulado não vai no corpo: a API o tira do token (RN-05), e por isso o `SimuladoCriar` deixou de pedir o `usuario_id`.
A validação acontece nas duas pontas: o `validator` de cada campo antes de enviar (identificação preenchida e data que existe, como 09/11/2025, e não 31/02), e a API, que recusa com 422; a frase da API aparece na tela. Excluir pede confirmação num diálogo. Depois de cada operação, a tela fecha com `true`, e a lista pede os simulados de novo.

---

## 🖼️ Protótipo Frontend

Uma pasta `prototipo/` conterá os prints das telas essenciais do frontend, servindo como referência visual para o desenvolvimento do backend.


</div>