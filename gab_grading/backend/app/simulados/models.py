from sqlalchemy import Boolean, Column, Date, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from ..database import Base

class Simulado(Base): # faz elo com Base do SQLAlchemy, que sabe quais tabelas existem
    """A TABELA que vira linha no banco.
    diferente de schema que atravessa a fronteira da API, 
    """

    __tablename__ = "simulados"

    id = Column(Integer, primary_key=True, index=True)
    identificacao = Column(String(120), nullable=False)
    data_aplicacao = Column(Date, nullable=False)
    usuario_id = Column(
        Integer, 
        ForeignKey("usuarios.id", name="fk_simulados_usuario")
    )
    ativo = Column(Boolean, nullable=False, default=True)

    # o dono: a ligacao que o SQLAlchemy monta em cima da coluna. simulado.usuario
    # e' o objeto Usuario inteiro, sem escrever consulta nenhuma.
    usuario = relationship("Usuario", back_populates="simulados")

    # o outro lado do relacionamento com Questao: um simulado, muitas
    # questoes. Nao cria coluna nenhuma -- a chave estrangeira mora em
    # questoes.simulado_id.
    questoes = relationship("Questao", back_populates="simulado")