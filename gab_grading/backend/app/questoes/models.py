import enum

from sqlalchemy import Column, Enum, ForeignKey, Integer, Text
from sqlalchemy.orm import relationship

from ..database import Base


class AlternativaCorreta(str, enum.Enum):
    """As únicas cinco respostas possíveis -- nunca texto livre (RN10)."""
    A = "A"
    B = "B"
    C = "C"
    D = "D"
    E = "E"

class Disciplina(str, enum.Enum):
    """As únicas cinco respostas possíveis -- nunca texto livre (RN10)."""
    PORTUGUES = "PORTUGUÊS"
    MATEMATICA = "MATEMÁTICA"
    CIENCIAS = "CIÊNCIAS"
    HISTORIA = "HISTÓRIA"
    GEOGRAFIA = "GEOGRAFIA"
    LITERATURA = "LITERATURA"
    GRAMATICA = "GRAMÁTICA"
    FILOSOFIA = "FILOSOFIA"
    SOCIOLOGIA = "SOCIOLOGIA"
    ARTES = "ARTES"
    INGLES = "INGLÊS"
    ESPANHOL = "ESPANHOL"
    LINGUA_EXTRANJERA = "LÍNGUA ESTRANGEIRA"
    QUIMICA = "QUÍMICA"
    BIOLOGIA = "BIOLOGIA"
    FISICA = "FÍSICA"
    EDUCACAO_FISICA = "EDUCAÇÃO FÍSICA"
    ENSINO_RELIGIOSO = "ENSINO RELIGIOSO"
    ATUALIDADES = "ATUALIDADES"


class Questao(Base):
    """A TABELA que vira linha no banco.
    Questao nunca existe sozinha: ela sempre pertence a um Simulado (RN11),
    e sua visibilidade é herdada do Simulado (RN13) -- essa herança é
    regra de negócio, então mora no service, não aqui no model.
    """

    __tablename__ = "questoes"

    id = Column(Integer, primary_key=True, index=True)
    # RN12: atribuído pelo sistema, em sequência, dentro do simulado. O
    # usuário nunca digita este valor.
    numero_questao = Column(Integer, nullable=False)
    componente_curricular = Column(Enum(Disciplina), nullable=False)
    alternativa_correta = Column(Enum(AlternativaCorreta), nullable=False)

    conteudo = Column(Text, nullable=True)

    # A POSSE, por tabela: toda questao aponta para o simulado dono dela.
    # Nasce NOT NULL porque a tabela e' nova -- nao ha' questao antiga sem
    # simulado para se preocupar.
    simulado_id = Column(
        Integer,
        ForeignKey("simulados.id", name="fk_questoes_simulado"),
        nullable=False,
    )
    simulado = relationship("Simulado", back_populates="questoes")