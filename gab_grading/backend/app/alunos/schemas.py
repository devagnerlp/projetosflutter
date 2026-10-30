from pydantic import BaseModel, ConfigDict, Field, field_validator

from ..turma.schema import nome_legivel


class AlunoCriar(BaseModel):          # ENTRA no cadastro
    nome: str = Field(max_length=120, description="Nome do aluno")
    # turma_id NAO entra aqui: e' posse, e vem da rota (/turmas/{id}/alunos).

    @field_validator("nome")
    @classmethod
    def nome_ok(cls, v):
        return nome_legivel(v)


class AlunoPublico(BaseModel):        # SAI na resposta
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    turma_id: int
    ativo: bool


class AlunoAtualizar(BaseModel):      # ENTRA na edicao
    nome: str | None = Field(None, max_length=120)
    # trocar o aluno de turma nao esta previsto no escopo.

    @field_validator("nome")
    @classmethod
    def nome_ok(cls, v):
        return v if v is None else nome_legivel(v)
