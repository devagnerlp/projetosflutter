import importlib

import app.main as principal

# O CORS e' montado quando o main.py e' importado, lendo a variavel
# ENDERECO_DO_APP. Para testar cada valor, o modulo e' importado de novo com a
# variavel posta, e depois volta ao que era (senao o proximo teste herdaria).


def opcoes_do_cors():
    for middleware in principal.app.user_middleware:
        if middleware.cls.__name__ == "CORSMiddleware":
            return middleware.kwargs
    raise AssertionError("o CORS nao esta montado")


def recarregar(monkeypatch, endereco):
    if endereco is None:
        monkeypatch.delenv("ENDERECO_DO_APP", raising=False)
    else:
        monkeypatch.setenv("ENDERECO_DO_APP", endereco)
    importlib.reload(principal)


def test_na_nuvem_o_cors_aceita_o_endereco_do_app(monkeypatch):
    try:
        recarregar(monkeypatch, "https://meu-app.onrender.com")

        assert opcoes_do_cors()["allow_origins"] == ["https://meu-app.onrender.com"]
    finally:
        monkeypatch.undo()
        importlib.reload(principal)


def test_a_barra_a_mais_no_fim_do_endereco_e_tirada(monkeypatch):
    # o navegador manda a origem sem a barra, e a comparacao e' exata
    try:
        recarregar(monkeypatch, "https://meu-app.onrender.com/")

        assert opcoes_do_cors()["allow_origins"] == ["https://meu-app.onrender.com"]
    finally:
        monkeypatch.undo()
        importlib.reload(principal)


def test_sem_a_variavel_so_o_localhost_e_aceito(monkeypatch):
    try:
        recarregar(monkeypatch, None)

        opcoes = opcoes_do_cors()
        assert opcoes["allow_origins"] == []
        assert "localhost" in opcoes["allow_origin_regex"]
    finally:
        monkeypatch.undo()
        importlib.reload(principal)
