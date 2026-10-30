from sqlalchemy import Boolean, Column, ForeignKey, Integer, String

from ..database import Base


class Aluno(Base):
    """A TABELA que vira linha no banco.

    O aluno nunca existe sozinho: ele sempre pertence a uma Turma, e a posse
    dele e' a da turma (que e' de um usuario) -- como a Questao com o Simulado.
    """

    __tablename__ = "alunos"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    turma_id = Column(
        Integer,
        ForeignKey("turmas.id", name="fk_alunos_turma"),
        nullable=False,
    )
    ativo = Column(Boolean, nullable=False, default=True)
