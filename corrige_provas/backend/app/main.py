from fastapi import FastAPI

from .database import BANCO, criar_banco
from .questoes.controller import router as questoes_router

criar_banco(BANCO)

app = FastAPI(title="Corrige Provas", version="0.1.1")
app.include_router(questoes_router)



# from .questoes import controller as questoes_controller
# A instancia da aplicacao. O titulo aparece na pagina /docs.
# app = FastAPI(title="API Corrige Provas", version="0.1.0")
# app.include_router(questoes_controller.router)
















