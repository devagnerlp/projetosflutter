from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .alunos import controller as alunos_controller
from .alunos.erros import AlunoNaoEncontrado, ErroDeAluno
from .questoes import controller as questoes_controller
from .questoes.erros import ErroDeQuestao, QuestaoNaoEncontrada
from .respostas import controller as respostas_controller
from .respostas.erros import ErroDeResposta, RespostaInvalida

#from .database import Base, engine - saiu pq não usa mais o create_all.
from .simulados import controller as simulados_controller
from .simulados.erros import ErroDeSimulado, SimuladoNaoEncontrado
from .turma import controller as turma_controller
from .turma.erros import ErroDeTurma, TurmaNaoEncontrada
from .usuarios import controller as usuarios_controller
from .usuarios.erros import CredenciaisInvalidas, ErroDeUsuario
from fastapi.middleware.cors import CORSMiddleware

# So' para a aula: cria as tabelas ao subir. Em projeto de verdade quem
# faz isso e' uma ferramenta de migracao (Alembic), assunto de outro dia.
#Base.metadata.create_all(bind=engine)

app = FastAPI(title="API do GabGrading", version="0.3.0")
# O app Flutter roda no navegador, noutro endereco (a porta muda a cada
# `flutter run`). O navegador so' deixa uma pagina falar com outro endereco
# se a API disser que deixa: e' o CORS. Aqui: qualquer porta desta maquina.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)
# é um app por rota nova (entidade nova) que criamos, e o controller é quem sabe quais rotas existem. O app não sabe nada de simulados, só sabe que existe um controller que sabe.
app.include_router(simulados_controller.router) #realiza guarda de rotas do controller de simulados - Padrão composite
app.include_router(questoes_controller.router)
app.include_router(turma_controller.router)
app.include_router(alunos_controller.router)
app.include_router(respostas_controller.router)
app.include_router(usuarios_controller.router) #realiza guarda de rotas do controller de usuarios - Padrão composite

# Cada familia de erros (uma por entidade) tem UMA recusa que vira um codigo
# proprio: "nao achei" e' 404, e "isso nao faz sentido" e' 422. Qualquer outra
# recusa da familia e' um conflito (409). Entidade nova: uma linha aqui.
RECUSAS = {
    ErroDeSimulado: (SimuladoNaoEncontrado, 404),
    ErroDeQuestao: (QuestaoNaoEncontrada, 404),
    ErroDeTurma: (TurmaNaoEncontrada, 404),
    ErroDeAluno: (AlunoNaoEncontrado, 404),
    # 422: o corpo chegou, mas nao faz sentido para este simulado.
    ErroDeResposta: (RespostaInvalida, 422),
}

def tradutor_de_recusa(recusa_especifica, codigo_da_especifica):
    """O unico lugar do sistema que transforma recusa em numero HTTP.

    Monta o tradutor de uma familia de erros: a recusa especifica vira o codigo
    dela, e as demais da familia viram 409.
    """
    def traduzir(request: Request, erro: Exception):
        codigo = codigo_da_especifica if isinstance(erro, recusa_especifica) else 409
        return JSONResponse(status_code=codigo, content={"detail": str(erro)})
    return traduzir

for familia, (especifica, codigo) in RECUSAS.items():
    app.add_exception_handler(familia, tradutor_de_recusa(especifica, codigo))

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