"""As regras do GabGrading para Turma, e mais nada.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e' o controller, quem fala SQL e' o
repository.

Toda regra recebe o `usuario` -- quem esta' pedindo. A turma e' do usuario
que a cadastrou, e so' ele a enxerga.
"""
from . import repository
from .erros import TurmaNaoEncontrada


def listar(db, usuario):
    # Soft delete: so' as ativas. E so' as do proprio usuario.
    return repository.listar(db, usuario.id, apenas_ativos=True)


def buscar(db, usuario, turma_id):
    turma = repository.buscar(db, turma_id)
    # Inexistente, inativa ou de outra pessoa: tudo se comporta como se a
    # turma nao existisse, e a mensagem nao diz qual dos tres casos foi.
    if turma is None or not turma.ativo or turma.usuario_id != usuario.id:
        raise TurmaNaoEncontrada(f"Turma {turma_id} nao esta no seu acervo")
    return turma


def criar(db, usuario, dados):
    # O dono vem de quem esta logado, nunca do corpo da requisicao.
    return repository.criar(db, {**dados, "usuario_id": usuario.id})


def atualizar(db, usuario, turma_id, mudancas):
    turma = buscar(db, usuario, turma_id)
    return repository.atualizar(db, turma, mudancas)


def desativar(db, usuario, turma_id):
    turma = buscar(db, usuario, turma_id)
    repository.desativar(db, turma)
