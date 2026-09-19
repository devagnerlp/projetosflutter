from sqlalchemy import Column, Integer, String, Boolean

from ..database import Base

class Usuario(Base):
    
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(80), nullable=False)
    email = Column(String(120), nullable=False, unique=True, index=True)
    senha_hash = Column(String(100), nullable=False)
    ativo = Column(Boolean, nullable=False, default=True)