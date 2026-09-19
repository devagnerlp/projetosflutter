"""As regras de conta e de login, e mais nada.

Nenhum HTTP, nenhum SQL e nenhum JWT aqui: o hash e o token vem de
app/seguranca.py; a consulta vem do repository. O service só decide.
"""
from .. import seguranca
from . import repository
from .erros import CredenciaisInvalidas, EmailJaCadastrado

def cadastrar(db, dados):
    # RN-01: um e-mail, uma conta.
    if repository.buscar_por_email(db, dados["email"]):
        raise EmailJaCadastrado(f"Ja existe uma conta com o e-mail {dados['email']}")

    # A senha em texto chega até aqui e NÃO passa deste ponto: o que vai para o banco é o hash. (RN-02)
    senha = dados.pop("senha")
    return repository.criar(db, {**dados, "senha_hash": seguranca.gerar_hash(senha)})

def autenticar(db, email, senha):
    usuario = repository.buscar_por_email(db, email)
    # RN-06: uma conta inativa nao consegue logar, mesmo com credenciais
    # corretas. A mensagem continua generica: nao diz SE o e-mail existe,
    # SE a senha esta errada ou SE a conta esta desativada.
    if (
        usuario is None
        or not usuario.ativo
        or not seguranca.conferir_senha(senha, usuario.senha_hash)
    ):
        raise CredenciaisInvalidas("E-mail ou senha incorretos")
    return usuario