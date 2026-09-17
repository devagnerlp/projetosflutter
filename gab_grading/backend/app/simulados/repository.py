from sqlalchemy.orm import Session

from .models import Simulado

# A UNICA parte do sistema que sabe que existe um banco. Não pode ter 'db.query` fora daqui, senão a camada vazou.

def listar(db: Session, apenas_ativos: bool = True):
    consulta = db.query(Simulado)
    if apenas_ativos:
        consulta = consulta.filter(Simulado.ativo == True)  # noqa: E712 (pela redução de linhas, o linter reclama do '== True')
    return consulta.all()

def buscar(db: Session, simulado_id: int):
    return db.query(Simulado).filter(Simulado.id == simulado_id).first()

def criar(db: Session, dados: dict):
    simulado = Simulado(**dados)
    db.add(simulado)
    db.commit()
    db.refresh(simulado)   # o id nasce no banco; sem isto ele vem None
    return simulado

def atualizar(db: Session, simulado: Simulado, mudancas: dict):
    for campo, valor in mudancas.items():
        setattr(simulado, campo, valor)
    db.commit()
    db.refresh(simulado)
    return simulado

def desativar(db: Session, simulado: Simulado):
    # RN09: nunca remove de verdade -- so marca como inativo.
    simulado.ativo = False
    db.commit()
    db.refresh(simulado)
    return simulado