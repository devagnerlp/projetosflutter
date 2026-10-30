from sqlalchemy.orm import Session

from .models import Turma

# A UNICA parte do sistema que sabe que existe uma tabela turmas. Se aparecer
# um db.query fora daqui, a camada vazou.


def listar(db: Session, usuario_id: int, apenas_ativos: bool = True):
    consulta = db.query(Turma).filter(Turma.usuario_id == usuario_id)
    if apenas_ativos:
        consulta = consulta.filter(Turma.ativo == True)  # noqa: E712
    return consulta.order_by(Turma.nome).all()


def buscar(db: Session, turma_id: int):
    return db.query(Turma).filter(Turma.id == turma_id).first()


def criar(db: Session, dados: dict):
    turma = Turma(**dados)
    db.add(turma)
    db.commit()
    db.refresh(turma)
    return turma


def atualizar(db: Session, turma: Turma, mudancas: dict):
    for campo, valor in mudancas.items():
        setattr(turma, campo, valor)
    db.commit()
    db.refresh(turma)
    return turma


def desativar(db: Session, turma: Turma):
    # Soft delete: o registro nunca sai do banco.
    turma.ativo = False
    db.commit()
    db.refresh(turma)
    return turma
