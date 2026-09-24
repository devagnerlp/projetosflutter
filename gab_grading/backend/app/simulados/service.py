"""As regras do GabGrading para Simulado, e mais nada.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e o controller, quem fala SQL e o
repository.
"""
from . import repository
from .erros import SimuladoNaoEncontrado
from .divisao_area import divisao_para



def listar(db):
    # RN18: por padrao, so mostra os simulados ativos.
    return repository.listar(db, apenas_ativos=True)


def buscar(db, simulado_id):
    simulado = repository.buscar(db, simulado_id)
    if simulado is None or not simulado.ativo:
        # RN18: um simulado inativo se comporta como se nao existisse.
        raise SimuladoNaoEncontrado(f"Simulado {simulado_id} nao encontrado")
    return simulado


def criar(db, dados):
    return repository.criar(db, dados)


def atualizar(db, simulado_id, mudancas):
    simulado = buscar(db, simulado_id)
    return repository.atualizar(db, simulado, mudancas)


def desativar(db, simulado_id):
    # RN09: apagar e' soft delete -- o registro nunca sai do banco.
    simulado = buscar(db, simulado_id)
    repository.desativar(db, simulado)

def area_da_questao(tipo_divisao, dados_divisao, numero_questao):
    """Pergunta a estrategia certa qual é a area de uma questao?

    tipo_divisao: "faixa" ou "lista_explicita"
    dados_divisao: as faixas (lista de tuplas) ou o mapa (dict), conforme o tipo
    """
    divisao = divisao_para(tipo_divisao, dados_divisao)
    return divisao.area_da_questao(numero_questao)