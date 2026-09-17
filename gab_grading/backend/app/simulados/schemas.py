from datetime import date
from pydantic import BaseModel, ConfigDict, Field

class SimuladoCriar(BaseModel):
    identificacao: str = Field(min_length=3, description="Identificação única do simulado")
    data_aplicacao: date = Field(description="Data de aplicação do simulado")
    usuario_id: int = Field(description="ID do usuário proprietário do simulado")
    ativo: bool = True

class SimuladoPublico(BaseModel):
    # Sem esta linha, o Pydantic so aceita dicionario -- e como quem
    # está chegando é um objeto do SQLAlchemy (linha), vindo do repository é preciso converter
    model_config = ConfigDict(from_attributes=True)

    id: int
    identificacao: str
    data_aplicacao: date
    usuario_id: int
    ativo: bool

class SimuladoAtualizar(BaseModel):
    identificacao: str | None = Field(None, min_length=3)
    data_aplicacao: date | None = None
    ativo: bool | None = None