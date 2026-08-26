from fastapi import APIRouter, HTTPException, status
from .schemas import CadastroQuestao, QuestaoRetorno, QuestaoAtualizar

router = APIRouter(prefix="/questoes", tags=["Questoes"])

# Banco de mentira: uma lista em memoria. Vira banco de verdade no encontro 4.
questoes: list[dict] = [
    {"id": 1, "numero": 1, "gabarito": "A", "assunto": "Frações"},
    {"id": 2, "numero": 2, "gabarito": "C", "assunto": "Porcentagem"},
    {"id": 3, "numero": 3, "gabarito": "B", "assunto": None},
    {"id": 4, "numero": 4, "gabarito": "D", "assunto": "Equações"},
    {"id": 5, "numero": 5, "gabarito": "A", "assunto": "Geometria"},
    {"id": 6, "numero": 6, "gabarito": "E", "assunto": "Operações"},
    {"id": 7, "numero": 7, "gabarito": "B", "assunto": "Frações"},
    {"id": 8, "numero": 8, "gabarito": "C", "assunto": "Álgebra"},
    {"id": 9, "numero": 9, "gabarito": "D", "assunto": "Medidas"},
    {"id": 10, "numero": 10, "gabarito": "A", "assunto": "Probabilidade"},
]

@router.get("/", response_model=list[QuestaoRetorno])
def listar():
    return questoes

@router.post("/", response_model=QuestaoRetorno, status_code=201)
def criar(dados: CadastroQuestao):
    novo = { "id": max((q["id"] for q in questoes), default=0) + 1, **dados.model_dump()} 
    # para id se basear no maior id já existente
    questoes.append(novo)
    return novo

@router.get("/{questao_id}", response_model=QuestaoRetorno)
def buscar(questao_id: int):
    for q in questoes:        
        if q["id"] == questao_id:
            return q
    raise HTTPException(status_code=404, detail="Questão não encontrada")

@router.patch("/{questao_id}", response_model=QuestaoRetorno)
def atualizar(questao_id: int, dados: QuestaoAtualizar):
    for q in questoes:
        if q["id"] == questao_id:
            q.update(dados.model_dump(exclude_unset=True))
            return q
    raise HTTPException(status_code=404, detail="Questão não encontrada")

@router.delete("/{questao_id}", status_code=204)
def apagar(questao_id: int):
    for q in questoes:
        if q["id"] == questao_id:
            questoes.remove(q)
            return
    raise HTTPException(status_code=404, detail="Questão não encontrada")