"""As regras do GabGrading para as respostas dos alunos e a correcao.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e' o controller, quem fala SQL e' o
repository, e a conta da nota mora em correcao.py.

Aqui moram as duas fachadas (padrao Facade) do sistema: `lancar` e `corrigir`.
Cada uma esconde varias pecas (simulado, aluno, questoes, respostas) atras de
uma chamada so'.
"""
from ..alunos import service as alunos_service
from ..questoes import service as questoes_service
from . import correcao, repository
from .erros import RespostaInvalida


def _preparar(db, usuario, simulado_id, aluno_id):
    # O simulado tem que ser do usuario, e o aluno tambem (pela turma dele).
    # questoes_service.listar ja' confere o simulado (existe, ativo e do dono).
    questoes = questoes_service.listar(db, usuario, simulado_id)
    aluno = alunos_service.buscar_por_id(db, usuario, aluno_id)
    return aluno, questoes


def listar(db, usuario, simulado_id, aluno_id):
    aluno, questoes = _preparar(db, usuario, simulado_id, aluno_id)
    numero_de = {q.id: q.numero_questao for q in questoes}
    respostas = repository.listar_do_aluno(db, aluno.id, simulado_id)
    return [
        {
            "numero_questao": numero_de[r.questao_id],
            "alternativa_escolhida": r.alternativa_escolhida,
        }
        for r in respostas
    ]


def lancar(db, usuario, simulado_id, aluno_id, itens):
    """Grava o gabarito do aluno neste simulado, substituindo o anterior.

    itens: lista de {"numero_questao": int, "alternativa": letra}. A questao
    que ficar de fora fica em branco (e conta como erro na correcao).
    """
    aluno, questoes = _preparar(db, usuario, simulado_id, aluno_id)
    por_numero = {q.numero_questao: q for q in questoes}

    vistos = set()
    for item in itens:
        numero = item["numero_questao"]
        if numero in vistos:
            raise RespostaInvalida(f"A questao {numero} veio mais de uma vez")
        vistos.add(numero)
        if numero not in por_numero:
            raise RespostaInvalida(f"O simulado {simulado_id} nao tem a questao {numero}")

    repository.substituir(
        db,
        aluno.id,
        [q.id for q in questoes],
        [(por_numero[i["numero_questao"]].id, i["alternativa"]) for i in itens],
    )
    return listar(db, usuario, simulado_id, aluno_id)


def corrigir(db, usuario, simulado_id, aluno_id):
    """A fachada da correcao: aluno_id e simulado_id entram, o resultado sai.

    1. confere que o simulado e o aluno sao do usuario;
    2. busca as questoes do simulado (o gabarito);
    3. busca o que o aluno marcou;
    4. compara e conta (correcao.calcular_resultado).
    """
    aluno, questoes = _preparar(db, usuario, simulado_id, aluno_id)
    numero_de = {q.id: q.numero_questao for q in questoes}
    marcadas = {
        numero_de[r.questao_id]: r.alternativa_escolhida
        for r in repository.listar_do_aluno(db, aluno.id, simulado_id)
    }
    gabarito = [
        (q.numero_questao, q.alternativa_correta, q.componente_curricular)
        for q in questoes
    ]
    resultado = correcao.calcular_resultado(gabarito, marcadas)
    return {"aluno_id": aluno.id, "simulado_id": simulado_id, **resultado}
