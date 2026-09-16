from fastapi import FastAPI

# A instancia da aplicacao. O titulo aparece na pagina /docs.
app = FastAPI(title="API GabGrading", version="0.1.0")

# O decorador diz: "esta funcao atende GET na raiz".
@app.get("/")
def raiz():
    # Devolvemos um dicionario. O FastAPI transforma em JSON sozinho.
    return {"mensagem": "A API do GabGrading esta no ar!"}

# Adicione este código abaixo da função 'raiz()'

@app.get("/simulados")
def listar_simulados():
    return [
        {"id": 1, "identificacao": "Simulado ENEM 2024", "data_aplicacao": "2024-11-01", "usuario_id": 1},
        {"id": 2, "identificacao": "Simulado Vestibular IFG", "data_aplicacao": "2025-01-15", "usuario_id": 1},
        {"id": 3, "identificacao": "Simulado Medicina", "data_aplicacao": "2025-06-20", "usuario_id": 2},
        {"id": 4, "identificacao": "Simulado UFJ", "data_aplicacao": "2025-08-20", "usuario_id": 2},
    ]