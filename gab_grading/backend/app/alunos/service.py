"""As regras do GabGrading para Aluno, e mais nada.

Este arquivo decide. Nao levanta erro de protocolo, nao monta consulta e
nao abre conexao: quem fala HTTP e' o controller, quem fala SQL e' o
repository.

A posse do aluno e' indireta: ele pertence a uma Turma, que pertence a um
usuario. Quem decide se a turma e' do usuario e' o service da turma.
"""
from ..turma import service as turma_service
from ..turma.erros import TurmaNaoEncontrada
from . import repository
from .erros import AlunoNaoEncontrado


def listar(db, usuario, turma_id):
    turma_service.buscar(db, usuario, turma_id)  # recusa turma que nao e' do usuario
    return repository.listar(db, turma_id)


def buscar(db, usuario, turma_id, aluno_id):
    turma_service.buscar(db, usuario, turma_id)
    aluno = repository.buscar(db, aluno_id)
    # Se o aluno nao existe, esta inativo ou nao e' DESTA turma, ele se
    # comporta como se nao existisse.
    if aluno is None or not aluno.ativo or aluno.turma_id != turma_id:
        raise AlunoNaoEncontrado(f"Aluno {aluno_id} nao encontrado")
    return aluno


def buscar_por_id(db, usuario, aluno_id):
    """Acha o aluno so' pelo id, conferindo que a turma dele e' do usuario.

    Serve a quem chega por outro caminho (as respostas), sem a turma na rota.
    """
    aluno = repository.buscar(db, aluno_id)
    if aluno is None or not aluno.ativo:
        raise AlunoNaoEncontrado(f"Aluno {aluno_id} nao encontrado")
    try:
        turma_service.buscar(db, usuario, aluno.turma_id)
    except TurmaNaoEncontrada:
        # A turma e' de outra pessoa (ou foi desativada): o aluno some junto.
        raise AlunoNaoEncontrado(f"Aluno {aluno_id} nao encontrado")
    return aluno


def criar(db, usuario, turma_id, dados):
    turma_service.buscar(db, usuario, turma_id)
    return repository.criar(db, {**dados, "turma_id": turma_id})


def atualizar(db, usuario, turma_id, aluno_id, mudancas):
    aluno = buscar(db, usuario, turma_id, aluno_id)
    return repository.atualizar(db, aluno, mudancas)


def desativar(db, usuario, turma_id, aluno_id):
    aluno = buscar(db, usuario, turma_id, aluno_id)
    repository.desativar(db, aluno)
