import json

import pytest

from app.alunos.erros import AlunoNaoEncontrado, ErroDeAluno
from app.main import app
from app.questoes.erros import ErroDeQuestao, QuestaoNaoEncontrada
from app.respostas.erros import ErroDeResposta, RespostaInvalida
from app.simulados.erros import ErroDeSimulado, SimuladoNaoEncontrado
from app.turma.erros import ErroDeTurma, TurmaNaoEncontrada
from app.usuarios.erros import CredenciaisInvalidas, EmailJaCadastrado, ErroDeUsuario

# O unico lugar do sistema que transforma recusa em numero HTTP (main.py). Aqui
# se chama o tradutor direto, como o FastAPI faria: a recusa entra, e sai a
# resposta com o codigo e a frase. O request nao e' usado, entao vai None.
# Cada linha: a familia de erros da entidade, a recusa e o codigo esperado.
CASOS = [
    (ErroDeSimulado, SimuladoNaoEncontrado, 404),
    (ErroDeSimulado, ErroDeSimulado, 409),
    (ErroDeQuestao, QuestaoNaoEncontrada, 404),
    (ErroDeQuestao, ErroDeQuestao, 409),
    (ErroDeTurma, TurmaNaoEncontrada, 404),
    (ErroDeTurma, ErroDeTurma, 409),
    (ErroDeAluno, AlunoNaoEncontrado, 404),
    (ErroDeAluno, ErroDeAluno, 409),
    (ErroDeResposta, RespostaInvalida, 422),
    (ErroDeResposta, ErroDeResposta, 409),
    (ErroDeUsuario, EmailJaCadastrado, 409),
]


@pytest.mark.parametrize("familia, recusa, codigo", CASOS)
def test_cada_recusa_vira_o_codigo_http_dela(familia, recusa, codigo):
    resposta = app.exception_handlers[familia](None, recusa("a frase da recusa"))

    assert resposta.status_code == codigo
    assert json.loads(resposta.body) == {"detail": "a frase da recusa"}


def test_credenciais_invalidas_viram_401_e_dizem_como_se_apresentar():
    resposta = app.exception_handlers[ErroDeUsuario](None, CredenciaisInvalidas("E-mail ou senha incorretos"))

    assert resposta.status_code == 401
    assert json.loads(resposta.body) == {"detail": "E-mail ou senha incorretos"}
    assert resposta.headers["www-authenticate"] == "Bearer"


@pytest.mark.parametrize("familia", [ErroDeSimulado, ErroDeQuestao, ErroDeTurma, ErroDeAluno, ErroDeResposta, ErroDeUsuario])
def test_toda_familia_de_erros_tem_um_tradutor_registrado(familia):
    assert familia in app.exception_handlers
