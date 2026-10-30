from pydantic import BaseModel, Field

from ..questoes.models import AlternativaCorreta, Disciplina


class RespostaEntrada(BaseModel):     # ENTRA: uma linha do gabarito do aluno
    numero_questao: int = Field(ge=1)
    alternativa: AlternativaCorreta


class RespostasLote(BaseModel):       # ENTRA: o gabarito do aluno, de uma vez
    respostas: list[RespostaEntrada] = Field(min_length=1)


class RespostaPublica(BaseModel):     # SAI: o que o aluno marcou
    numero_questao: int
    alternativa_escolhida: AlternativaCorreta


class AcertosPorComponente(BaseModel):
    componente: Disciplina
    acertos: int
    total: int


class ResultadoPublico(BaseModel):    # SAI: a correcao
    aluno_id: int
    simulado_id: int
    total_questoes: int
    total_acertos: int
    nota: float                       # de 0 a 10
    acertos_por_componente: list[AcertosPorComponente]  # RN-20
