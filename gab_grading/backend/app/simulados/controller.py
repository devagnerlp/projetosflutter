# backend/app/simulados/controller.py
from fastapi import APIRouter, HTTPException, status
from typing import List
from .schemas import SimuladoCriar, SimuladoPublico, SimuladoAtualizar

# Cria um roteador para agrupar as rotas de simulados
router = APIRouter(prefix="/simulados", tags=["Simulados"])

# Banco de mentira: uma lista em memória para armazenar os simulados.
# Isso será substituído por um banco de dados real na sequência
simulados_db: List[dict] = []

@router.post("/", response_model=SimuladoPublico, status_code=status.HTTP_201_CREATED)
def criar_simulado(dados: SimuladoCriar):
    """
    Cria um novo simulado no sistema.
    """
    novo_simulado = dados.model_dump()
    novo_simulado["id"] = len(simulados_db) + 1  # ID simples para dados em memória
    simulados_db.append(novo_simulado)
    return novo_simulado

@router.get("/", response_model=List[SimuladoPublico])
def listar_simulados():
    """
    Lista todos os simulados cadastrados.
    """
    return simulados_db

@router.get("/{simulado_id}", response_model=SimuladoPublico)
def buscar_simulado(simulado_id: int):
    """
    Busca um simulado específico pelo seu ID.
    Retorna 404 se o simulado não for encontrado.
    """
    for simulado in simulados_db:
        if simulado["id"] == simulado_id:
            return simulado
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Simulado não encontrado")

@router.patch("/{simulado_id}", response_model=SimuladoPublico)
def atualizar_simulado(simulado_id: int, dados: SimuladoAtualizar):
    """
    Atualiza parcialmente um simulado existente pelo seu ID.
    Retorna 404 se o simulado não for encontrado.
    """
    for simulado in simulados_db:
        if simulado["id"] == simulado_id:
            # Atualiza apenas os campos que foram enviados na requisição
            # exclude_unset=True garante que campos não enviados não sobrescrevam os existentes com None
            simulado.update(dados.model_dump(exclude_unset=True))
            return simulado
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Simulado não encontrado")

@router.delete("/{simulado_id}", status_code=status.HTTP_204_NO_CONTENT)
def apagar_simulado(simulado_id: int):
    """
    Apaga um simulado existente pelo seu ID.
    Retorna 404 se o simulado não for encontrado.
    """
    global simulados_db  # Necessário para modificar a lista global
    for i, simulado in enumerate(simulados_db):
        if simulado["id"] == simulado_id:
            del simulados_db[i]
            return
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Simulado não encontrado")