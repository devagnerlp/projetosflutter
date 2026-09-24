from pydantic import BaseModel, ConfigDict, field_validator

from .models import AlternativaCorreta, Disciplina


def _conteudo_legivel(conteudo):
    # Conteúdo é opcional (RN10 só exige numero_questao e alternativa_correta e componente_curricular), mas se vier preenchido, não pode ser só espaço em branco.
    # mas se vier preenchido, nao pode ser só espaco em branco.
    if conteudo is not None and len(conteudo.strip()) == 0:
        raise ValueError("O conteúdo, se enviado, não pode ser vazio")
    return conteudo.strip() if conteudo else conteudo


class QuestaoCriar(BaseModel):        # ENTRA no cadastro
    alternativa_correta: AlternativaCorreta
    componente_curricular: Disciplina
    conteudo: str | None = None
    # numero_questao NÃO entra aqui: RN12, quem atribui é o sistema.
    # simulado_id NÃO entra aqui: É posse, e vem da rota (/simulados/{id}/questoes),
    # não do corpo 

    @field_validator("conteudo")
    @classmethod
    def conteudo_legivel(cls, v):
        return _conteudo_legivel(v)


class QuestaoPublica(BaseModel):      # SAI na resposta
    model_config = ConfigDict(from_attributes=True)

    id: int
    numero_questao: int
    alternativa_correta: AlternativaCorreta
    componente_curricular: Disciplina
    conteudo: str | None
    simulado_id: int


class QuestaoAtualizar(BaseModel):    # ENTRA na edição, tudo opcional
    alternativa_correta: AlternativaCorreta | None = None
    componente_curricular: Disciplina | None = None
    conteudo: str | None = None
    # numero_questao e simulado_id continuam de fora: RN12 não se edita,
    # e trocar uma questao de simulado não está previsto no escopo.

    @field_validator("conteudo")
    @classmethod
    def conteudo_legivel(cls, v):
        return v if v is None else _conteudo_legivel(v)