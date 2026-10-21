"""As regras do GabGrading para Simulado, e mais nada.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e o controller, quem fala SQL e o
repository.
"""
from . import repository
from .erros import SimuladoNaoEncontrado
from .divisao_area import divisao_para



def listar(db, usuario_id=None):
    # RN18: por padrao, so mostra os simulados ativos.
    # RN-08: e so os de quem pediu.
    return repository.listar(db, apenas_ativos=True, usuario_id=usuario_id)


def buscar(db, simulado_id, usuario_id=None):
    simulado = repository.buscar(db, simulado_id)
    if simulado is None or not simulado.ativo:
        # RN18: um simulado inativo se comporta como se nao existisse.
        raise SimuladoNaoEncontrado(f"Simulado {simulado_id} nao encontrado")
    if usuario_id is not None and simulado.usuario_id != usuario_id:
        # RN-08: o de outra pessoa tambem se comporta como se nao existisse.
        raise SimuladoNaoEncontrado(f"Simulado {simulado_id} nao esta no seu acervo")
    return simulado


def criar(db, dados):
    return repository.criar(db, dados)


def atualizar(db, simulado_id, mudancas, usuario_id=None):
    simulado = buscar(db, simulado_id, usuario_id)
    return repository.atualizar(db, simulado, mudancas)


def desativar(db, simulado_id, usuario_id=None):
    # RN09: apagar e' soft delete -- o registro nunca sai do banco.
    simulado = buscar(db, simulado_id, usuario_id)
    repository.desativar(db, simulado)

def area_da_questao(tipo_divisao, dados_divisao, numero_questao):
    """Pergunta a estrategia certa qual é a area de uma questao?

    tipo_divisao: "faixa" ou "lista_explicita"
    dados_divisao: as faixas (lista de tuplas) ou o mapa (dict), conforme o tipo
    """
    divisao = divisao_para(tipo_divisao, dados_divisao)
    return divisao.area_da_questao(numero_questao)