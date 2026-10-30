from pydantic import BaseModel, ConfigDict, Field, field_validator


def nome_legivel(nome):
    # Um nome so' com espacos em branco nao serve: o min_length conta os espacos.
    nome = nome.strip()
    if len(nome) < 2:
        raise ValueError("O nome precisa ter pelo menos 2 caracteres")
    return nome


class TurmaCriar(BaseModel):          # ENTRA no cadastro
    nome: str = Field(max_length=120, description="Nome da turma, ex.: 3o ano A")
    # usuario_id NAO entra aqui: e' posse, e vem do token de quem esta logado.

    @field_validator("nome")
    @classmethod
    def nome_ok(cls, v):
        return nome_legivel(v)


class TurmaPublica(BaseModel):        # SAI na resposta
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    ativo: bool


class TurmaAtualizar(BaseModel):      # ENTRA na edicao
    nome: str | None = Field(None, max_length=120)

    @field_validator("nome")
    @classmethod
    def nome_ok(cls, v):
        return v if v is None else nome_legivel(v)
