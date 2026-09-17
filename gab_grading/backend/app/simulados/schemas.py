from datetime import date
from pydantic import BaseModel, Field

# Modelo para criar um novo Simulado (o que o cliente envia)
class SimuladoCriar(BaseModel):
    identificacao: str = Field(min_length=3, description="Identificação única do simulado")
    data_aplicacao: date = Field(description="Data de aplicação do simulado no formato YYYY-MM-DD")
    # usuario_id virá do token no futuro, mas para dados em memória, incluímos aqui por enquanto
    usuario_id: int = Field(description="ID do usuário proprietário do simulado")
    ativo: bool = True

# Modelo para a resposta pública do Simulado (o que a API devolve)
class SimuladoPublico(BaseModel):
    id: int = Field(description="ID único do simulado")
    identificacao: str = Field(description="Identificação única do simulado")
    data_aplicacao: date = Field(description="Data de aplicação do simulado")
    usuario_id: int = Field(description="ID do usuário proprietário do simulado")
    ativo: bool = Field(description="Status de atividade do simulado")

# Modelo para atualizar um Simulado (o que o cliente envia para edição)
# Todos os campos são opcionais para permitir atualizações parciais
class SimuladoAtualizar(BaseModel):
    identificacao: str | None = Field(None, min_length=3, description="Nova identificação do simulado")
    data_aplicacao: date | None = Field(None, description="Nova data de aplicação do simulado")
    ativo: bool | None = Field(None, description="Novo status de atividade do simulado")