from sqlalchemy import Boolean, Column, ForeignKey, Integer, String

from ..database import Base


class Turma(Base):
    """A TABELA que vira linha no banco.

    A turma pertence a um usuario (quem a cadastrou), e e' ela que da' posse
    aos alunos: um aluno so' existe dentro de uma turma.
    """

    __tablename__ = "turmas"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", name="fk_turmas_usuario"),
        nullable=False,
    )
    ativo = Column(Boolean, nullable=False, default=True)
