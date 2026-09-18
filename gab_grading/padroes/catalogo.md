# Catálogo de padrões — gab_grading

Este arquivo cresce o semestre inteiro.
A última coluna começa vazia e só é preenchida quando o padrão for
aplicado de verdade no projeto.

## 🧩 Padrão 1

- **🏷️ Padrão:** 
Strategy

- **👨‍👩‍👧‍👦 Família:** 
Comportamental  

- **🛠️ Que problema resolve:**  
Uma regra que muda de caso para caso vira uma escada de if que cresce a cada caso novo 

- **📍 Onde caberia no meu projeto:** 
Nas estratégias de correção, cálculo de notas, filtros ou ordenações 

- **✅ Já usei? Onde:**  

-----------------------------------------------------------------

## 🧩 Padrão 2

- **🏷️ Padrão:**
Chain of Responsibility

- **👨‍👩‍👧‍👦 Família:**
Comportamental  

- **🛠️ Que problema resolve:** 
Organiza uma sequência de validações e autorizações. 

- **📍 Onde caberia no meu projeto:** 
Na autenticação, verificação do usuário ativo, controle de posse e validação do estado do simulado. 

- **✅ Já usei? Onde:**  

-----------------------------------------------------------------

## 🧩 Padrão 3

- **🏷️ Padrão:** 
Proxy 

- **👨‍👩‍👧‍👦 Família:** 
Estrutural 

- **🛠️ Que problema resolve:** 
Controla o acesso a um objeto ou serviço antes de encaminhar a operação. 

- **📍 Onde caberia no meu projeto:** 
Na proteção de simulados e questões, garantindo que o usuário acesse apenas seus próprios registros ativos. 

- **✅ Já usei? Onde:**  

-----------------------------------------------------------------

## 🧩 Padrão 4

- **🏷️ Padrão:** 
Facade 

- **👨‍👩‍👧‍👦 Família:** 
Estrutural 

- **🛠️ Que problema resolve:** 
Simplifica operações que envolvem vários componentes internos. 

- **📍 Onde caberia no meu projeto:**
Na camada service.py, coordenando validações, autenticação, controle de posse, repositories e regras de negócio.  

- **✅ Já usei? Onde:**  


-------------------------------------- **PADRÕES APLICADOS** --------------------------------------

💉 **Injeção de Dependência**

*- Onde está:* em backend/app/simulados/controller.py, toda rota recebe db: Session = Depends(get_db) e a fábrica é a função get_db, dentro de backend/app/database.py, que abre uma Session, entrega com yield e fecha no finally quando a requisição termina.

*- Que problema resolve:* sem isso, cada uma das cinco rotas do controller precisaria abrir a própria Session manualmente (SessionLocal()) e lembrar de fechar depois, repetindo essa lógica cinco vezes. O controller passaria a saber como o banco é conectado — coisa que não é da conta dele.

*- O que aconteceria sem ele:* eu teria que escrever db = SessionLocal() no início de cada função de rota e db.close() no fim de cada uma, com risco real de esquecer o close() em alguma delas e vazar conexão. Também ficaria impossível trocar a Session de produção por uma de teste sem editar as cinco rotas uma por uma.

*- Quando vale e quando é burocracia:* no meu projeto vale, porque as cinco rotas precisam exatamente da mesma peça montada do mesmo jeito, e o FastAPI já entrega esse mecanismo pronto — não precisei escrever nenhuma fábrica complexa, só a função get_db. Seria burocracia se eu tivesse uma única rota isolada usando algo trivial, o que não é o meu caso.


⛓️ **Corrente de Responsabilidade**


*- Onde está:* em backend/app/main.py, o @app.exception_handler(ErroDeSimulado) — um único tratador registrado para toda a aplicação, que intercepta qualquer exceção herdada de ErroDeSimulado (hoje, SimuladoNaoEncontrado) e a transforma em resposta HTTP.

*- Que problema resolve:* sem esse tratador, cada uma das rotas de controller.py que dependem do service.py (buscar, atualizar, desativar) precisaria de um try/except SimuladoNaoEncontrado repetido, traduzindo a mesma exceção no mesmo código 404 em três lugares diferentes.

*- O que aconteceria sem ele:* eu teria que lembrar de colocar try/except nas três rotas que usam buscar por baixo dos panos, e se um dia o código de erro mudasse (por exemplo, de 404 para outro valor), teria que lembrar de editar em três lugares. É exatamente por isso que meu controller.py não tem nenhum try — verifiquei com Ctrl+F e não existe um único no arquivo.

*- Quando vale e quando é burocracia:* vale porque o mesmo tratamento (recusa vira 404) se repete em todas as rotas que dependem do service.buscar. Seria burocracia se cada rota precisasse de um tratamento totalmente diferente e sem repetição nenhuma — não é o caso aqui.


🗂️ **Composite**


*- Onde está:* em backend/app/main.py, a linha app.include_router(simulados_controller.router).

*- Que problema resolve:* sem isso, as cinco rotas de /simulados (GET /, POST /, GET /{id}, PATCH /{id}, DELETE /{id}) precisariam ser declaradas uma a uma dentro do próprio main.py, misturando a definição das rotas de simulado com a configuração geral da aplicação.

*- O que aconteceria sem ele:* o main.py cresceria uma seção inteira por entidade nova. Quando eu adicionar usuarios ou questoes ao GabGrading, o main.py ficaria enorme, e ler o arquivo inteiro para entender "quais rotas o sistema tem" ficaria impraticável.

*- Quando vale e quando é burocracia:* vale porque as rotas se agrupam naturalmente por entidade (simulados hoje, usuários e questões depois), e o main.py não precisa saber o que tem dentro de cada grupo — só inclui. Seria burocracia se o projeto tivesse, e sempre fosse ter, só três rotas soltas sem nenhuma perspectiva de crescer em grupos.

