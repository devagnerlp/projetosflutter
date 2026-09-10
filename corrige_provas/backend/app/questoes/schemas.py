from pydantic import BaseModel, Field

class CadastroQuestao(BaseModel):
    simulado_id: int = Field(gt=0)
    numero: int = Field(gt=0)
    gabarito: str = Field(min_length=1, max_length=1)
    area_conhecimento: str | None = None
    assunto: str | None = None
    


class QuestaoRetorno(BaseModel):
    id: int
    simulado_id: int
    numero: int
    gabarito: str
    area_conhecimento: str | None = None
    assunto: str | None = None


class QuestaoAtualizar(BaseModel):
    numero: int | None = Field(default=None, gt=0)
    simulado_id: int | None = Field(default=None, gt=0)
    gabarito: str | None = Field(
        default=None,
        min_length=1,
        max_length=1,
    )
    area_conhecimento: str | None = None
    assunto: str | None = None