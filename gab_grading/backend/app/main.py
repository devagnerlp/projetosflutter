from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .database import Base, engine
from .simulados import controller as simulados_controller
from .simulados.erros import ErroDeSimulado, SimuladoNaoEncontrado

# So' para a aula: cria as tabelas ao subir. Em projeto de verdade quem
# faz isso e' uma ferramenta de migracao (Alembic), assunto de outro dia.
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do GabGrading", version="0.3.0")
app.include_router(simulados_controller.router)

@app.exception_handler(ErroDeSimulado)
def traduzir_recusa(request: Request, erro: ErroDeSimulado):
    """O unico lugar do sistema que transforma recusa em numero HTTP."""
    codigo = 404 if isinstance(erro, SimuladoNaoEncontrado) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})



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