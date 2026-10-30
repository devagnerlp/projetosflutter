from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..seguranca import get_current_user
from ..usuarios.models import Usuario
from . import service
from .schemas import AlunoAtualizar, AlunoCriar, AlunoPublico

# O aluno nunca existe fora de uma turma: o turma_id vem do caminho.
router = APIRouter(
    prefix="/turmas/{turma_id}/alunos",
    tags=["Alunos"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[AlunoPublico])
def listar(
    turma_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.listar(db, usuario, turma_id)


@router.post("/", response_model=AlunoPublico, status_code=201)
def criar(
    turma_id: int,
    dados: AlunoCriar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.criar(db, usuario, turma_id, dados.model_dump())


@router.get("/{aluno_id}", response_model=AlunoPublico)
def buscar(
    turma_id: int,
    aluno_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.buscar(db, usuario, turma_id, aluno_id)


@router.patch("/{aluno_id}", response_model=AlunoPublico)
def atualizar(
    turma_id: int,
    aluno_id: int,
    dados: AlunoAtualizar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.atualizar(
        db, usuario, turma_id, aluno_id, dados.model_dump(exclude_unset=True)
    )


@router.delete("/{aluno_id}", status_code=204)
def desativar(
    turma_id: int,
    aluno_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service.desativar(db, usuario, turma_id, aluno_id)
