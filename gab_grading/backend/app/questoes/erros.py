class ErroDeQuestao(Exception):
    """Qualquer recusa sobre uma questao. Quem traduz para HTTP e o controller."""


class QuestaoNaoEncontrada(ErroDeQuestao):
    """É pedido uma questão que não existe, ou cujo simulado não existe
    ou está inativo (RN13) -- a visibilidade da questão é herdada do
    simulado, então ela se comporta como se nao existisse.
    """