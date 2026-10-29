import pytest

from app import seguranca
from app.usuarios import service
from app.usuarios.erros import CredenciaisInvalidas, EmailJaCadastrado


def dados_da_ana():
    return {"nome": "Ana", "email": "ana@x.com", "senha": "segredo123"}


def test_cadastrar_guarda_o_hash_e_nao_a_senha(db):
    usuario = service.cadastrar(db, dados_da_ana())

    assert usuario.id is not None
    assert usuario.senha_hash != "segredo123"
    assert seguranca.conferir_senha("segredo123", usuario.senha_hash)


def test_cadastrar_recusa_email_repetido(db):
    service.cadastrar(db, dados_da_ana())

    with pytest.raises(EmailJaCadastrado):
        service.cadastrar(db, dados_da_ana())


def test_autenticar_com_a_senha_certa_devolve_o_usuario(db):
    service.cadastrar(db, dados_da_ana())

    usuario = service.autenticar(db, "ana@x.com", "segredo123")

    assert usuario.email == "ana@x.com"


@pytest.mark.parametrize("email, senha", [("ana@x.com", "errada"), ("outra@x.com", "segredo123")])
def test_autenticar_recusa_senha_errada_ou_email_inexistente(db, email, senha):
    service.cadastrar(db, dados_da_ana())

    with pytest.raises(CredenciaisInvalidas):
        service.autenticar(db, email, senha)


def test_conta_inativa_nao_consegue_logar(db):
    usuario = service.cadastrar(db, dados_da_ana())
    usuario.ativo = False
    db.commit()

    with pytest.raises(CredenciaisInvalidas):
        service.autenticar(db, "ana@x.com", "segredo123")