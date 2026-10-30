from sqlalchemy.orm import Session

from ..questoes.models import Questao
from .models import Resposta

# A UNICA parte do sistema que sabe que existe uma tabela respostas.


def listar_do_aluno(db: Session, aluno_id: int, simulado_id: int):
    # So' as respostas de questoes DESTE simulado (a resposta aponta para a
    # questao, e a questao e' que aponta para o simulado).
    return (
        db.query(Resposta)
        .join(Questao, Resposta.questao_id == Questao.id)
        .filter(Resposta.aluno_id == aluno_id, Questao.simulado_id == simulado_id)
        .order_by(Questao.numero_questao)
        .all()
    )


def substituir(db: Session, aluno_id: int, questao_ids: list[int], novas: list[tuple]):
    """Troca as respostas do aluno nas questoes dadas pelas novas, de uma vez.

    novas: lista de (questao_id, alternativa). Apaga as antigas e grava as
    novas num commit so': ou entra tudo, ou nada.
    """
    (
        db.query(Resposta)
        .filter(Resposta.aluno_id == aluno_id, Resposta.questao_id.in_(questao_ids))
        .delete(synchronize_session=False)
    )
    for questao_id, alternativa in novas:
        db.add(
            Resposta(
                aluno_id=aluno_id,
                questao_id=questao_id,
                alternativa_escolhida=alternativa,
            )
        )
    db.commit()
