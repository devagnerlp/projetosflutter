import jwt
import pytest

from app import seguranca


def test_o_hash_nao_e_a_senha():
    # RN-02: a senha nunca é guardada em texto puro
    assert seguranca.gerar_hash("segredo123") != "segredo123"


def test_senha_certa_confere_e_errada_nao():
    hash_da_senha = seguranca.gerar_hash("segredo123")

    assert seguranca.conferir_senha("segredo123", hash_da_senha) is True
    assert seguranca.conferir_senha("outra-senha", hash_da_senha) is False


def test_a_mesma_senha_gera_hashes_diferentes():
    # o bcrypt mistura um "sal" aleatório em cada hash
    assert seguranca.gerar_hash("segredo123") != seguranca.gerar_hash("segredo123")


def test_o_token_guarda_quem_e_o_usuario_e_quando_vence():
    token = seguranca.criar_token(7)

    dados = jwt.decode(token, seguranca.SECRET_KEY, algorithms=[seguranca.ALGORITMO])

    assert dados["sub"] == "7"
    assert "exp" in dados

from app.usuarios.erros import CredenciaisInvalidas


def test_porteiro_recusa_token_assinado_com_outra_chave():
    token_falso = jwt.encode(
        {"sub": "7"}, "outra-chave-qualquer-com-mais-de-32-bytes", algorithm="HS256"
    )

    # chamamos a função do projeto direto, sem FastAPI; o db nem é usado,
    # porque o token é recusado antes de qualquer consulta
    with pytest.raises(CredenciaisInvalidas):
        seguranca.get_current_user(token=token_falso, db=None)