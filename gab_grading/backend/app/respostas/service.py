"""As regras do GabGrading para as respostas dos alunos.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e' o controller, quem fala SQL e' o
repository, e a conta da nota mora em correcao.py.

Ele so' conhece o assunto "respostas". Quem confere o simulado e o aluno, e
junta tudo na ordem certa, e' a fachada (fachada.py): aqui chegam o aluno ja'
conferido e as questoes do simulado ja' buscadas.
"""
from . import repository
from .erros import RespostaInvalida


def _conferir_itens(itens, por_numero, simulado_id):
    # RN-23: o gabarito que chegou tem que fazer sentido para ESTE simulado:
    # nenhuma questao repetida, e so' questoes que ele tem. Qualquer problema
    # recusa o gabarito inteiro, antes de gravar qualquer coisa.
    vistos = set()
    for item in itens:
        numero = item["numero_questao"]
        if numero in vistos:
            raise RespostaInvalida(f"A questao {numero} veio mais de uma vez")
        vistos.add(numero)
        if numero not in por_numero:
            raise RespostaInvalida(f"O simulado {simulado_id} nao tem a questao {numero}")


def listar(db, aluno_id, simulado_id, questoes):
    """O que o aluno marcou neste simulado, em ordem de numero.

    Devolve uma lista de {"numero_questao", "alternativa_escolhida"}.
    """
    numero_de = {q.id: q.numero_questao for q in questoes}
    respostas = repository.listar_do_aluno(db, aluno_id, simulado_id)
    return [
        {
            "numero_questao": numero_de[r.questao_id],
            "alternativa_escolhida": r.alternativa_escolhida,
        }
        for r in respostas
    ]


def gravar(db, aluno_id, simulado_id, questoes, itens):
    """Grava o gabarito do aluno, substituindo o anterior (RN-23).

    itens: lista de {"numero_questao": int, "alternativa": letra}. A questao
    que ficar de fora fica em branco (e conta como erro na correcao).
    """
    por_numero = {q.numero_questao: q for q in questoes}
    _conferir_itens(itens, por_numero, simulado_id)
    repository.substituir(
        db,
        aluno_id,
        [q.id for q in questoes],
        [(por_numero[i["numero_questao"]].id, i["alternativa"]) for i in itens],
    )
