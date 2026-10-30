class ErroDeTurma(Exception):
    """Qualquer recusa sobre uma turma. Quem traduz para HTTP e' o main.py."""


class TurmaNaoEncontrada(ErroDeTurma):
    """Pediram uma turma que nao existe, esta inativa ou e' de outra pessoa."""
