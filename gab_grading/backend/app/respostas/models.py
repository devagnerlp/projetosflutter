from sqlalchemy import Column, Enum, ForeignKey, Integer, UniqueConstraint

from ..database import Base
from ..questoes.models import AlternativaCorreta


class Resposta(Base):
    """A TABELA que vira linha no banco: o que UM aluno marcou numa questao.

    A mesma letra A-E do gabarito (AlternativaCorreta), porque e' a mesma
    coisa vista do outro lado: a letra certa e a letra marcada.
    """

    __tablename__ = "respostas"
    # Um aluno so' tem uma resposta por questao.
    __table_args__ = (
        UniqueConstraint("aluno_id", "questao_id", name="uq_respostas_aluno_questao"),
    )

    id = Column(Integer, primary_key=True, index=True)
    aluno_id = Column(
        Integer,
        ForeignKey("alunos.id", name="fk_respostas_aluno"),
        nullable=False,
    )
    questao_id = Column(
        Integer,
        ForeignKey("questoes.id", name="fk_respostas_questao"),
        nullable=False,
    )
    alternativa_escolhida = Column(Enum(AlternativaCorreta), nullable=False)
