from sqlalchemy import Boolean, Column, Date, Integer, String

from ..database import Base

class Simulado(Base): # faz elo com Base do SQLAlchemy, que sabe quais tabelas existem
    """A TABELA que vra linha no banco.
    diferente de schema que atravessa a fronteira da API, 
    """

    __tablename__ = "simulados"

    id = Column(Integer, primary_key=True, index=True)
    identificacao = Column(String(120), nullable=False)
    data_aplicacao = Column(Date, nullable=False)
    usuario_id = Column(Integer, nullable=False)
    ativo = Column(Boolean, nullable=False, default=True)