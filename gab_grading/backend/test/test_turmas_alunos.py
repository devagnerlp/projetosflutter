import pytest

from app.alunos import repository as alunos_repository
from app.alunos import service as alunos_service
from app.alunos.erros import AlunoNaoEncontrado
from app.turma import repository as turma_repository
from app.turma import service as turma_service
from app.turma.erros import TurmaNaoEncontrada
from app.usuarios import service as usuarios_service


def criar_usuario(db, email):
    return usuarios_service.cadastrar(db, {"nome": "Fulano", "email": email, "senha": "segredo123"})


def test_listar_turmas_mostra_so_as_do_dono(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    turma_service.criar(db, ana, {"nome": "3o A"})
    turma_service.criar(db, bia, {"nome": "3o B"})

    assert [t.nome for t in turma_service.listar(db, ana)] == ["3o A"]


def test_a_turma_de_outra_pessoa_se_comporta_como_inexistente(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})

    with pytest.raises(TurmaNaoEncontrada):
        turma_service.buscar(db, bia, turma.id)
    with pytest.raises(TurmaNaoEncontrada):
        turma_service.atualizar(db, bia, turma.id, {"nome": "Invadida"})
    assert turma_repository.buscar(db, turma.id).nome == "3o A"


def test_o_dono_da_turma_vem_do_usuario_logado(db):
    ana = criar_usuario(db, "ana@x.com")

    turma = turma_service.criar(db, ana, {"nome": "3o A", "usuario_id": 999})

    assert turma.usuario_id == ana.id


def test_desativar_turma_e_soft_delete(db):
    ana = criar_usuario(db, "ana@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})

    turma_service.desativar(db, ana, turma.id)

    assert turma_repository.buscar(db, turma.id).ativo is False
    assert turma_service.listar(db, ana) == []
    with pytest.raises(TurmaNaoEncontrada):
        turma_service.buscar(db, ana, turma.id)


def test_cria_e_lista_alunos_da_turma_em_ordem_de_nome(db):
    ana = criar_usuario(db, "ana@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})
    alunos_service.criar(db, ana, turma.id, {"nome": "Zeca"})
    alunos_service.criar(db, ana, turma.id, {"nome": "Bruno"})

    assert [a.nome for a in alunos_service.listar(db, ana, turma.id)] == ["Bruno", "Zeca"]


def test_nao_cria_aluno_na_turma_de_outra_pessoa(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})

    with pytest.raises(TurmaNaoEncontrada):
        alunos_service.criar(db, bia, turma.id, {"nome": "Intruso"})

    assert alunos_service.listar(db, ana, turma.id) == []


def test_aluno_buscado_por_uma_turma_que_nao_e_a_dele(db):
    ana = criar_usuario(db, "ana@x.com")
    turma_a = turma_service.criar(db, ana, {"nome": "3o A"})
    turma_b = turma_service.criar(db, ana, {"nome": "3o B"})
    aluno = alunos_service.criar(db, ana, turma_a.id, {"nome": "Bruno"})

    with pytest.raises(AlunoNaoEncontrado):
        alunos_service.buscar(db, ana, turma_b.id, aluno.id)


def test_buscar_aluno_pelo_id_confere_o_dono_da_turma(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})
    aluno = alunos_service.criar(db, ana, turma.id, {"nome": "Bruno"})

    assert alunos_service.buscar_por_id(db, ana, aluno.id).nome == "Bruno"
    with pytest.raises(AlunoNaoEncontrado):
        alunos_service.buscar_por_id(db, bia, aluno.id)


def test_desativar_a_turma_esconde_os_alunos(db):
    ana = criar_usuario(db, "ana@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})
    aluno = alunos_service.criar(db, ana, turma.id, {"nome": "Bruno"})

    turma_service.desativar(db, ana, turma.id)

    with pytest.raises(AlunoNaoEncontrado):
        alunos_service.buscar_por_id(db, ana, aluno.id)


def test_desativar_aluno_e_soft_delete(db):
    ana = criar_usuario(db, "ana@x.com")
    turma = turma_service.criar(db, ana, {"nome": "3o A"})
    aluno = alunos_service.criar(db, ana, turma.id, {"nome": "Bruno"})

    alunos_service.desativar(db, ana, turma.id, aluno.id)

    assert alunos_repository.buscar(db, aluno.id).ativo is False
    assert alunos_service.listar(db, ana, turma.id) == []
