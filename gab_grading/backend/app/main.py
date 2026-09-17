from fastapi import FastAPI
from .simulados import controller as simulados_controller # Importa o roteador de simulados

app = FastAPI(title="API do GabGrading", version="0.1.0")

# Inclui o roteador de simulados na aplicação principal
app.include_router(simulados_controller.router) #registra todas as rotas definidas no roteador de simulados

@app.get("/")
def raiz():
    return {"mensagem": "A API do GabGrading está no ar!"}