from pydantic import BaseModel, Field

class CadastroQuestao(BaseModel):
    numero: int = Field(gt=0)
    gabarito: str = Field(min_length=1, max_length=1)
    assunto: str | None = None


class QuestaoRetorno(BaseModel):
    id: int
    numero: int
    gabarito: str
    assunto: str | None = None


class QuestaoAtualizar(BaseModel):
    numero: int | None = Field(default=None, gt=0)
    gabarito: str | None = Field(
        default=None,
        min_length=1,
        max_length=1,
    )
    assunto: str | None = None