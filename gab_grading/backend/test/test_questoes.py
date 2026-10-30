from datetime import date

import pytest

from app.questoes import service
from app.questoes.erros import QuestaoNaoEncontrada
from app.questoes.models import AlternativaCorreta, Disciplina
from app.simulados import service as simulados_service
from app.simulados.erros import SimuladoNaoEncontrado
from app.usuarios import service as usuarios_service


def criar_usuario(db, email):
    return usuarios_service.cadastrar(db, {"nome": "Fulano", "email": email, "senha": "segredo123"})


def criar_simulado(db, dono):
    return simulados_service.criar(
        db, {"identificacao": "Simulado A", "data_aplicacao": date(2026, 10, 1), "usuario_id": dono.id}
    )


def dados_da_questao(alternativa=AlternativaCorreta.A):
    return {"alternativa_correta": alternativa, "componente_curricular": Disciplina.MATEMATICA, "conteudo": None}


def test_a_numeracao_e_sequencial_dentro_do_simulado(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)

    q1 = service.criar(db, ana, simulado.id, dados_da_questao())
    q2 = service.criar(db, ana, simulado.id, dados_da_questao())
    q3 = service.criar(db, ana, simulado.id, dados_da_questao())

    assert [q1.numero_questao, q2.numero_questao, q3.numero_questao] == [1, 2, 3]


def test_cada_simulado_comeca_a_numeracao_do_um(db):
    ana = criar_usuario(db, "ana@x.com")
    primeiro = criar_simulado(db, ana)
    segundo = criar_simulado(db, ana)
    service.criar(db, ana, primeiro.id, dados_da_questao())
    service.criar(db, ana, primeiro.id, dados_da_questao())

    questao = service.criar(db, ana, segundo.id, dados_da_questao())

    assert questao.numero_questao == 1


def test_nao_cria_questao_no_simulado_de_outra_pessoa(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    simulado = criar_simulado(db, ana)

    with pytest.raises(QuestaoNaoEncontrada):
        service.criar(db, bia, simulado.id, dados_da_questao())

    assert service.listar(db, ana, simulado.id) == []


def test_nao_cria_questao_em_simulado_que_nao_existe(db):
    ana = criar_usuario(db, "ana@x.com")

    with pytest.raises(SimuladoNaoEncontrado):
        service.criar(db, ana, 999, dados_da_questao())


def test_listar_devolve_as_questoes_em_ordem_de_numero(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)
    for _ in range(3):
        service.criar(db, ana, simulado.id, dados_da_questao())

    questoes = service.listar(db, ana, simulado.id)

    assert [q.numero_questao for q in questoes] == [1, 2, 3]


def test_questoes_somem_quando_o_simulado_e_desativado(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)
    questao = service.criar(db, ana, simulado.id, dados_da_questao())

    simulados_service.desativar(db, simulado.id, ana.id)

    with pytest.raises(SimuladoNaoEncontrado):
        service.listar(db, ana, simulado.id)
    with pytest.raises(SimuladoNaoEncontrado):
        service.buscar(db, ana, simulado.id, questao.id)


def test_buscar_questao_por_um_simulado_que_nao_e_o_dela(db):
    ana = criar_usuario(db, "ana@x.com")
    primeiro = criar_simulado(db, ana)
    segundo = criar_simulado(db, ana)
    questao = service.criar(db, ana, primeiro.id, dados_da_questao())

    with pytest.raises(QuestaoNaoEncontrada):
        service.buscar(db, ana, segundo.id, questao.id)


def test_atualizar_muda_a_alternativa_e_mantem_o_numero(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado = criar_simulado(db, ana)
    questao = service.criar(db, ana, simulado.id, dados_da_questao(AlternativaCorreta.A))

    atualizada = service.atualizar(
        db, ana, simulado.id, questao.id, {"alternativa_correta": AlternativaCorreta.C}
    )

    assert atualizada.alternativa_correta == AlternativaCorreta.C
    assert atualizada.numero_questao == 1