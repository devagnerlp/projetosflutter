from pydantic import BaseModel, ConfigDict, Field, field_validator


# O tamanho do nome de uma turma ou de um aluno. O maximo e' o tamanho da coluna
# String(120) das tabelas turmas e alunos: mudar um exige mudar o outro (e uma
# migracao).
NOME_MINIMO = 2
NOME_MAXIMO = 120


def nome_legivel(nome):
    # Um nome so' com espacos em branco nao serve: o min_length conta os espacos.
    nome = nome.strip()
    if len(nome) < NOME_MINIMO:
        raise ValueError(f"O nome precisa ter pelo menos {NOME_MINIMO} caracteres")
    return nome


class TurmaCriar(BaseModel):          # ENTRA no cadastro
    nome: str = Field(max_length=NOME_MAXIMO, description="Nome da turma, ex.: 3o ano A")
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
    nome: str | None = Field(None, max_length=NOME_MAXIMO)

    @field_validator("nome")
    @classmethod
    def nome_ok(cls, v):
        return v if v is None else nome_legivel(v)
