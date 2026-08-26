from fastapi import FastAPI
from .questoes import controller as questoes_controller

# A instancia da aplicacao. O titulo aparece na pagina /docs.
app = FastAPI(title="API Corrige Provas", version="0.1.0")

app.include_router(questoes_controller.router)
















