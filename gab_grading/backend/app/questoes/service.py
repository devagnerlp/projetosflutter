"""As regras do GabGrading para Questao, e mais nada.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e o controller, quem fala SQL e o
repository.

Toda regra recebe o `usuario` -- quem esta' pedindo. A posse de Questao e'
indireta: ela pertence a um Simulado, que pertence a um usuario (RN11).
"""
from ..simulados import service as simulados_service
from . import repository
from .erros import QuestaoNaoEncontrada


def _simulado_do_usuario(db, usuario, simulado_id):
    # RN11: toda Questão precisa apontar para um simulado que exista e
    # pertence ao usuario logado -- mesma lógica de posse do Simulado.
    # simulados_service.buscar já recusa (404) simulado inexistente ou
    # inativo (RN18); aqui só falta conferir o dono.
    simulado = simulados_service.buscar(db, simulado_id)
    if simulado.usuario_id != usuario.id:
        raise QuestaoNaoEncontrada(
            f"Simulado {simulado_id} não está no seu acervo"
        )
    return simulado


def listar(db, usuario, simulado_id):
    _simulado_do_usuario(db, usuario, simulado_id)
    return repository.listar(db, simulado_id)


def buscar(db, usuario, simulado_id, questao_id):
    _simulado_do_usuario(db, usuario, simulado_id)
    questao = repository.buscar(db, questao_id)
    # RN13: a visibilidade e' herdada do simulado. Se a questao nao existe,
    # ou nao pertence a ESTE simulado, ela se comporta como se nao existisse.
    if questao is None or questao.simulado_id != simulado_id:
        raise QuestaoNaoEncontrada(f"Questao {questao_id} nao encontrada")
    return questao


def criar(db, usuario, simulado_id, dados):
    _simulado_do_usuario(db, usuario, simulado_id)
    numero = repository.proximo_numero(db, simulado_id)  # RN12
    return repository.criar(db, {**dados, "simulado_id": simulado_id, "numero_questao": numero})


def atualizar(db, usuario, simulado_id, questao_id, mudancas):
    questao = buscar(db, usuario, simulado_id, questao_id)
    return repository.atualizar(db, questao, mudancas)