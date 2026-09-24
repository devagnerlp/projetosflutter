from sqlalchemy import func
from sqlalchemy.orm import Session

from .models import Questao

# A UNICA parte do sistema que sabe que existe um banco. Se aparecer um
# db.query fora daqui, a camada vazou.


def listar(db: Session, simulado_id: int):
    # RN15: a listagem de Questões de um simulado é ordenada por numero_questao.
    return (
        db.query(Questao)
        .filter(Questao.simulado_id == simulado_id)
        .order_by(Questao.numero_questao)
        .all()
    )


def buscar(db: Session, questao_id: int):
    return db.query(Questao).filter(Questao.id == questao_id).first()


def proximo_numero(db: Session, simulado_id: int) -> int:
    # RN12: o número nasce da sequência dentro do simulado, nunca do usuário.
    # Pega o maior numero_questao já usado neste simulado e soma 1; se ainda
    # não há nenhuma questão, comeca em 1.
    maior = (
        db.query(func.max(Questao.numero_questao))
        .filter(Questao.simulado_id == simulado_id)
        .scalar()
    )
    return (maior or 0) + 1


def criar(db: Session, dados: dict):
    questao = Questao(**dados)
    db.add(questao)
    db.commit()
    db.refresh(questao)  # o id nasce no banco; sem isto ele vem None
    return questao


def atualizar(db: Session, questao: Questao, mudancas: dict):
    for campo, valor in mudancas.items():
        setattr(questao, campo, valor)
    db.commit()
    db.refresh(questao)
    return questao