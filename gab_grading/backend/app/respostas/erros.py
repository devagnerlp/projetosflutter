class ErroDeResposta(Exception):
    """Qualquer recusa sobre as respostas de um aluno. Quem traduz para HTTP e' o main.py."""


class RespostaInvalida(ErroDeResposta):
    """O gabarito do aluno veio com algo que nao faz sentido para o simulado.

    Por exemplo: a mesma questao duas vezes, ou uma questao que o simulado nao tem.
    """
