from fastapi import FastAPI

from .database import Base, engine
from .simulados import models  # importa para a tabela ser registrada na Base

# cria as tabelas ao subir. 
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do GabGrading", version="0.2.0")

@app.get("/")
def raiz():
    return {"status": "De pé", "mensagem": "API do GabGrading funcionando!"}