class ErroDeSimulado(Exception):
    """Qualquer recusa sobre um simulado. Quem traduz para HTTP e o controller."""

class SimuladoNaoEncontrado(ErroDeSimulado):
    """Pediram um simulado que nao existe, ou que esta inativo."""

class TipoDeDivisaoDesconhecido(Exception):
    """Levantada quando alguem pede uma divisao de area que nao existe."""
    pass

class AreaNaoEncontrada(Exception):
    """Levantada quando uma questao nao cai em nenhuma faixa nem esta no mapa."""
    pass