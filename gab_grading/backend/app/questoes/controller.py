from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..seguranca import get_current_user
from ..usuarios.models import Usuario
from . import service
from .schemas import QuestaoAtualizar, QuestaoCriar, QuestaoPublica

# A porta continua no router: nenhuma rota roda sem token. simulado_id vem
# do caminho -- Questão nunca existe fora de um simulado (RN11).
router = APIRouter(
    prefix="/simulados/{simulado_id}/questoes",
    tags=["Questoes"],
    dependencies=[Depends(get_current_user)],
)


@router.get("/", response_model=list[QuestaoPublica])
def listar(
    simulado_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.listar(db, usuario, simulado_id)


@router.post("/", response_model=QuestaoPublica, status_code=201)
def criar(
    simulado_id: int,
    dados: QuestaoCriar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.criar(db, usuario, simulado_id, dados.model_dump())


@router.get("/{questao_id}", response_model=QuestaoPublica)
def buscar(
    simulado_id: int,
    questao_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.buscar(db, usuario, simulado_id, questao_id)


@router.patch("/{questao_id}", response_model=QuestaoPublica)
def atualizar(
    simulado_id: int,
    questao_id: int,
    dados: QuestaoAtualizar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.atualizar(
        db, usuario, simulado_id, questao_id, dados.model_dump(exclude_unset=True)
    )