from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .questoes import controller as questoes_controller
from .questoes.erros import ErroDeQuestao, QuestaoNaoEncontrada

#from .database import Base, engine - saiu pq não usa mais o create_all.
from .simulados import controller as simulados_controller
from .simulados.erros import ErroDeSimulado, SimuladoNaoEncontrado
from .usuarios import controller as usuarios_controller
from .usuarios.erros import CredenciaisInvalidas, ErroDeUsuario

# So' para a aula: cria as tabelas ao subir. Em projeto de verdade quem
# faz isso e' uma ferramenta de migracao (Alembic), assunto de outro dia.
#Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do GabGrading", version="0.3.0")
# é um app por rota nova (entidade nova) que criamos, e o controller é quem sabe quais rotas existem. O app não sabe nada de simulados, só sabe que existe um controller que sabe.
app.include_router(simulados_controller.router) #realiza guarda de rotas do controller de simulados - Padrão composite
app.include_router(questoes_controller.router)
app.include_router(usuarios_controller.router) #realiza guarda de rotas do controller de usuarios - Padrão composite

@app.exception_handler(ErroDeSimulado)
def traduzir_recusa(request: Request, erro: ErroDeSimulado):
    """O unico lugar do sistema que transforma recusa em numero HTTP."""
    codigo = 404 if isinstance(erro, SimuladoNaoEncontrado) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})

@app.exception_handler(ErroDeQuestao)
def traduzir_recusa_de_questao(request: Request, erro: ErroDeQuestao):
    codigo = 404 if isinstance(erro, QuestaoNaoEncontrada) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})

@app.exception_handler(ErroDeUsuario)
def traduzir_recusa_de_usuario(request: Request, erro: ErroDeUsuario):
    if isinstance(erro, CredenciaisInvalidas):
        # 401 e' "nao sei quem voce e'". O cabecalho diz como se apresentar.
        return JSONResponse(
            status_code=401,
            content={"detail": str(erro)},
            headers={"WWW-Authenticate": "Bearer"},
        )
    return JSONResponse(status_code=409, content={"detail": str(erro)})

"""
from fastapi import FastAPI

from .database import Base, engine
from .simulados import models  # importa para a tabela ser registrada na Base

# cria as tabelas ao subir. 
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do GabGrading", version="0.2.0")

@app.get("/")
def raiz():
    return {"status": "De pé", "mensagem": "API do GabGrading funcionando!"}
"""