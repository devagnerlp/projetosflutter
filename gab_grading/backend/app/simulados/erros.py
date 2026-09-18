class ErroDeSimulado(Exception):
    """Qualquer recusa sobre um simulado. Quem traduz para HTTP e o controller."""

class SimuladoNaoEncontrado(ErroDeSimulado):
    """Pediram um simulado que nao existe, ou que esta inativo."""