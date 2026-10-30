from sqlalchemy.orm import Session

from .models import Aluno

# A UNICA parte do sistema que sabe que existe uma tabela alunos.


def listar(db: Session, turma_id: int, apenas_ativos: bool = True):
    consulta = db.query(Aluno).filter(Aluno.turma_id == turma_id)
    if apenas_ativos:
        consulta = consulta.filter(Aluno.ativo == True)  # noqa: E712
    return consulta.order_by(Aluno.nome).all()


def buscar(db: Session, aluno_id: int):
    return db.query(Aluno).filter(Aluno.id == aluno_id).first()


def criar(db: Session, dados: dict):
    aluno = Aluno(**dados)
    db.add(aluno)
    db.commit()
    db.refresh(aluno)
    return aluno


def atualizar(db: Session, aluno: Aluno, mudancas: dict):
    for campo, valor in mudancas.items():
        setattr(aluno, campo, valor)
    db.commit()
    db.refresh(aluno)
    return aluno


def desativar(db: Session, aluno: Aluno):
    # Soft delete: o registro nunca sai do banco (as respostas dele ficam).
    aluno.ativo = False
    db.commit()
    db.refresh(aluno)
    return aluno
