from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from ..database import Base

class Usuario(Base):
    
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(80), nullable=False)
    email = Column(String(120), nullable=False, unique=True, index=True)
    senha_hash = Column(String(100), nullable=False)
    ativo = Column(Boolean, nullable=False, default=True)


    # o outro lado do relacionamento: um usuario, muitos simulados. Nao cria
    # coluna nenhuma -- a chave estrangeira mora em simulados.usuario_id.
    simulados = relationship("Simulado", back_populates="usuario")