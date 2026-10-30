from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..seguranca import get_current_user
from ..usuarios.models import Usuario
from . import service
from .schema import RespostaPublica, RespostasLote, ResultadoPublico

# As respostas sao de UM aluno em UM simulado: os dois ids vem do caminho.
router = APIRouter(
    prefix="/simulados/{simulado_id}/alunos/{aluno_id}",
    tags=["Respostas e correcao"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/respostas", response_model=list[RespostaPublica])
def listar(
    simulado_id: int,
    aluno_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.listar(db, usuario, simulado_id, aluno_id)


@router.put("/respostas", response_model=list[RespostaPublica])
def lancar(
    simulado_id: int,
    aluno_id: int,
    dados: RespostasLote,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # PUT: o gabarito do aluno e' substituido por inteiro, nao acrescentado.
    itens = [item.model_dump() for item in dados.respostas]
    return service.lancar(db, usuario, simulado_id, aluno_id, itens)


@router.get("/resultado", response_model=ResultadoPublico)
def corrigir(
    simulado_id: int,
    aluno_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.corrigir(db, usuario, simulado_id, aluno_id)
