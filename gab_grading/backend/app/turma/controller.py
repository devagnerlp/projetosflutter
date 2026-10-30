from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..seguranca import get_current_user
from ..usuarios.models import Usuario
from . import service
from .schema import TurmaAtualizar, TurmaCriar, TurmaPublica

# A porta no router: nenhuma rota roda sem token.
router = APIRouter(
    prefix="/turmas",
    tags=["Turmas"],
    dependencies=[Depends(get_current_user)],
)

# Nenhum `if` de regra e nenhum `try` aqui: as recusas do Service viram
# HTTP no tradutor registrado no main.py, uma vez para todas as rotas.


@router.get("/", response_model=list[TurmaPublica])
def listar(
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.listar(db, usuario)


@router.post("/", response_model=TurmaPublica, status_code=201)
def criar(
    dados: TurmaCriar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.criar(db, usuario, dados.model_dump())


@router.get("/{turma_id}", response_model=TurmaPublica)
def buscar(
    turma_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.buscar(db, usuario, turma_id)


@router.patch("/{turma_id}", response_model=TurmaPublica)
def atualizar(
    turma_id: int,
    dados: TurmaAtualizar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.atualizar(
        db, usuario, turma_id, dados.model_dump(exclude_unset=True)
    )


@router.delete("/{turma_id}", status_code=204)
def desativar(
    turma_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service.desativar(db, usuario, turma_id)
