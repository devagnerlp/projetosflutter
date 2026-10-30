from datetime import date

import pytest

from app.simulados import repository, service
from app.simulados.erros import SimuladoNaoEncontrado
from app.usuarios import service as usuarios_service


def criar_usuario(db, email):
    return usuarios_service.cadastrar(db, {"nome": "Fulano", "email": email, "senha": "segredo123"})


def criar_simulado(db, dono, identificacao="Simulado A"):
    return service.criar(
        db,
        {"identificacao": identificacao, "data_aplicacao": date(2026, 10, 1), "usuario_id": dono.id},
    )


def test_listar_mostra_so_os_simulados_do_dono(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    criar_simulado(db, ana, "Simulado da Ana")
    criar_simulado(db, bia, "Simulado da Bia")

    da_ana = service.listar(db, ana.id)

    assert [s.identificacao for s in da_ana] == ["Simulado da Ana"]


def test_buscar_o_simulado_de_outra_pessoa_se_comporta_como_inexistente(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    simulado = criar_simulado(db, ana)

    with pytest.raises(SimuladoNaoEncontrado):
        service.buscar(db, simulado.id, bia.id)


def test_buscar_simulado_que_nao_existe(db):
    ana = criar_usuario(db, "ana@x.com")

    with pytest.raises(SimuladoNaoEncontrado):
        service.buscar(db, 999, ana.id)


def test_desativar_e_soft_delete_o_registro_continua_no_banco(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)

    service.desativar(db, simulado.id, ana.id)

    assert repository.buscar(db, simulado.id).ativo is False
    assert service.listar(db, ana.id) == []
    with pytest.raises(SimuladoNaoEncontrado):
        service.buscar(db, simulado.id, ana.id)


def test_atualizar_muda_a_identificacao_do_proprio_simulado(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)

    atualizado = service.atualizar(db, simulado.id, {"identificacao": "Novo nome"}, ana.id)

    assert atualizado.identificacao == "Novo nome"


def test_atualizar_o_simulado_de_outra_pessoa_e_recusado(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    simulado = criar_simulado(db, ana)

    with pytest.raises(SimuladoNaoEncontrado):
        service.atualizar(db, simulado.id, {"identificacao": "Invadido"}, bia.id)

    assert repository.buscar(db, simulado.id).identificacao == "Simulado A"