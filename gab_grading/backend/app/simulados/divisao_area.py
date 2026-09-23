# app/simulados/divisao_area.py
"""As estrategias de divisao de area por questao (padrao Strategy).

Cada simulado organiza suas questoes em areas de um jeito proprio. Alguns
usam faixas continuas e sequenciais (a questao 1 a 10 e Matematica). Outros
tem areas embaralhadas, sem seguir uma sequencia (a questao 3 e Quimica, a 4
e Historia, a 5 e Quimica de novo) -- nesse caso so' uma lista explicita,
questao a questao, resolve.

Aqui cada jeito vira um objeto, e os dois respondem a MESMA pergunta: qual
e' a area desta questao? Quem usa (o service.py) nao precisa saber qual dos
dois esta' respondendo.

A pergunta "qual tipo de divisao e' este?" existe no sistema inteiro uma vez
so': em `divisao_para`, no fim deste arquivo.
"""
from .erros import AreaNaoEncontrada, TipoDeDivisaoDesconhecido


class DivisaoDeArea:
    """O contrato: toda divisao responde a esta pergunta.

    O service.py so' conhece esta classe. As de baixo existem para ele
    sem nome.
    """

    def area_da_questao(self, numero_questao):
        """Devolve o nome da area a que pertence a questao de numero dado."""
        raise NotImplementedError


class DivisaoPorFaixa(DivisaoDeArea):
    """Areas organizadas em intervalos continuos e sequenciais de questoes.

    Exemplo: Matematica de 1 a 45, Ciencias da Natureza de 46 a 90.
    """

    def __init__(self, faixas):
        # faixas: lista de tuplas (nome_area, inicio, fim), ambos inclusivos
        self.faixas = faixas

    def area_da_questao(self, numero_questao):
        for nome, inicio, fim in self.faixas:
            if inicio <= numero_questao <= fim:
                return nome
        raise AreaNaoEncontrada(
            f"Questao {numero_questao} nao esta em nenhuma faixa cadastrada"
        )


class DivisaoPorListaExplicita(DivisaoDeArea):
    """Areas definidas questao a questao, sem depender de sequencia.

    Exemplo: dentro de Ciencias Humanas, a questao 3 e Geografia, a 4 e
    Historia, a 5 e Geografia de novo -- nao ha faixa que resolva isso.
    """

    def __init__(self, mapa):
        # mapa: dict {numero_questao: nome_area}
        self.mapa = mapa

    def area_da_questao(self, numero_questao):
        if numero_questao not in self.mapa:
            raise AreaNaoEncontrada(
                f"Questao {numero_questao} nao tem area definida na lista"
            )
        return self.mapa[numero_questao]


# O unico lugar do sistema que sabe quais tipos de divisao existem.
# Aqui o dicionario guarda as CLASSES, nao os objetos prontos: cada divisao
# precisa dos dados daquele simulado (as faixas ou o mapa) para nascer, e
# esse dado so' existe quando um simulado especifico e' consultado.
DIVISOES = {
    "faixa": DivisaoPorFaixa,
    "lista_explicita": DivisaoPorListaExplicita,
}


def divisao_para(tipo, dados):
    """Troca o nome do tipo pela divisao ja montada com os dados do simulado.

    A escolha acontece aqui, e so' aqui.
    """
    if tipo not in DIVISOES:
        aceitos = ", ".join(DIVISOES)
        raise TipoDeDivisaoDesconhecido(
            f"Tipo de divisao desconhecido: {tipo!r} (aceitos: {aceitos})"
        )
    classe = DIVISOES[tipo]
    return classe(dados)