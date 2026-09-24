Regras de Negócio 📋

**Usuário (Autenticação)** 👤🔐

📧 RN-01- O e-mail é único no sistema; o cadastro rejeita e-mail já existente, retornando uma mensagem clara em vez de um erro genérico de banco. **Implementada**

🔒 RN-02- A senha nunca é armazenada em texto puro — apenas o hash dela é gravado.**Implementada**

🎫 RN-03-  O login confere o hash da senha e, se bater, emite um token JWT. **Implementada**

🚫 RN-04- Toda rota de Simulado e de Questão exige um token válido; sem ele, a resposta é 401 Unauthorized. **Implementada**

🛡️ RN-05- O usuario_id de um Simulado nunca vem do corpo da requisição — é sempre extraído do token de quem está logado, para impedir que alguém crie ou edite dados em nome de outro usuário. **Implementada**

🗑️ RN-06- Exclusão de conta é soft delete: o campo ativo passa de true para false. O login deve checar ativo = true além de e-mail e senha — uma conta inativa não consegue logar, mesmo com credenciais corretas. **Implementada**

**Simulado** 📝

⚠️ RN-07- identificacao e data_aplicacao são obrigatórios e não podem chegar vazios, tanto no formulário quanto na validação da API.

👤🔒 RN-08- Um usuário só pode listar, ver, editar ou apagar os próprios simulados; tentativa de acessar um simulado de outro usuário retorna 404 Forbidden. 

🗂️ RN-09- Exclusão de Simulado também é soft delete: o campo ativo passa para false, e o registro nunca é removido de fato do banco — o que evita erro de integridade com as Questões já vinculadas a ele e preserva o histórico. **Implementada**

**Questão** ❓

✅ RN-10- numero_questao e alternativa_correta e componete_curricular são obrigatórios; alternativa_correta é um enum fechado (A a E) assim como componente_curricular, nunca texto livre.

🔗 RN-11- Toda Questão precisa apontar para um simulado_id que exista e pertença ao usuário logado — mesma lógica de posse do Simulado.

🔢 RN-12- numero_questao é atribuído automaticamente pelo sistema, em sequência crescente dentro do simulado, no momento em que a questão é adicionada; o usuário nunca digita esse valor. Por construção, não existe a possibilidade de duplicidade dentro do mesmo simulado; não há necessidade de validação de unicidade em tempo de gravação. Reordenação de numeração (caso o usuário reorganize as questões antes de salvar) é tratada no formulário, antes da gravação — não há exclusão isolada de questão após salva nesta etapa.

👁️ RN-13- A visibilidade de uma Questão é herdada do Simulado ao qual ela pertence: se o Simulado estiver com ativo = false, nenhuma consulta deve retornar suas Questões, mesmo que a busca seja feita diretamente pelo id da Questão. A entidade Questão não possui campo próprio de exclusão nesta etapa; exclusão isolada de uma questão individual foi identificada como decisão pertencente à fase futura de correção, dado seu impacto direto no cálculo de nota.

**Regras Transversais** 🔄

🔍 RN-14- A listagem de simulados aceita busca por identificacao e, opcionalmente, filtro por período de data_aplicacao.

📊 RN-15- A listagem de Questões de um simulado aceita busca ou ordenação por numero_questao.

💬 RN-16- Toda ação de criar, editar ou apagar retorna uma resposta clara — sucesso com o registro afetado, ou erro com mensagem compreensível — nunca um 500 genérico.

✔️ RN-17- Validação acontece nas duas pontas: no formulário antes de enviar, e na API antes de gravar, sem confiar apenas na validação da tela.

📌 RN-18- Toda listagem (GET) filtra por padrão apenas registros com ativo = true — um registro "excluído" não aparece mais nas telas, mesmo continuando no banco. **Implementada**

🧮 RN-20- O sistema deve apresentar a quantidade de acertos por componente curricular para cada aluno
