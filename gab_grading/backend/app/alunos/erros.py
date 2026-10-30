class ErroDeAluno(Exception):
    """Qualquer recusa sobre um aluno. Quem traduz para HTTP e' o main.py."""


class AlunoNaoEncontrado(ErroDeAluno):
    """Pediram um aluno que nao existe, esta inativo ou e' de outra pessoa."""
