from datetime import date

import pytest

from app.alunos import service as alunos_service
from app.alunos.erros import AlunoNaoEncontrado
from app.questoes import service as questoes_service
from app.questoes.erros import QuestaoNaoEncontrada
from app.questoes.models import AlternativaCorreta as Alt
from app.questoes.models import Disciplina
from app.respostas import service
from app.respostas.erros import RespostaInvalida
from app.simulados import service as simulados_service
from app.simulados.erros import SimuladoNaoEncontrado
from app.turma import service as turma_service
from app.usuarios import service as usuarios_service


def criar_usuario(db, email):
    return usuarios_service.cadastrar(db, {"nome": "Fulano", "email": email, "senha": "segredo123"})


def montar_cenario(db, usuario):
    """Um simulado de 3 questoes (2 de Matematica, 1 de Portugues) e um aluno.

    Gabarito: 1=A (Mat), 2=B (Mat), 3=C (Port).
    """
    simulado = simulados_service.criar(
        db, {"identificacao": "Simulado A", "data_aplicacao": date(2026, 10, 1), "usuario_id": usuario.id}
    )
    for letra, disciplina in [(Alt.A, Disciplina.MATEMATICA), (Alt.B, Disciplina.MATEMATICA), (Alt.C, Disciplina.PORTUGUES)]:
        questoes_service.criar(
            db, usuario, simulado.id,
            {"alternativa_correta": letra, "componente_curricular": disciplina, "conteudo": None},
        )
    turma = turma_service.criar(db, usuario, {"nome": "3o A"})
    aluno = alunos_service.criar(db, usuario, turma.id, {"nome": "Bruno"})
    return simulado, aluno


def item(numero, letra):
    return {"numero_questao": numero, "alternativa": letra}


def test_lancar_grava_e_devolve_o_gabarito_do_aluno_em_ordem(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)

    gravadas = service.lancar(db, ana, simulado.id, aluno.id, [item(3, Alt.C), item(1, Alt.A)])

    assert [(r["numero_questao"], r["alternativa_escolhida"]) for r in gravadas] == [(1, Alt.A), (3, Alt.C)]


def test_lancar_de_novo_substitui_o_gabarito_anterior(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)
    service.lancar(db, ana, simulado.id, aluno.id, [item(1, Alt.A), item(2, Alt.B), item(3, Alt.C)])

    service.lancar(db, ana, simulado.id, aluno.id, [item(1, Alt.E)])

    atuais = service.listar(db, ana, simulado.id, aluno.id)
    assert [(r["numero_questao"], r["alternativa_escolhida"]) for r in atuais] == [(1, Alt.E)]


def test_lancar_recusa_a_mesma_questao_duas_vezes(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)

    with pytest.raises(RespostaInvalida):
        service.lancar(db, ana, simulado.id, aluno.id, [item(1, Alt.A), item(1, Alt.B)])

    assert service.listar(db, ana, simulado.id, aluno.id) == []


def test_lancar_recusa_questao_que_o_simulado_nao_tem_e_nao_grava_nada(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)

    with pytest.raises(RespostaInvalida):
        service.lancar(db, ana, simulado.id, aluno.id, [item(1, Alt.A), item(99, Alt.B)])

    # tudo ou nada: a questao 1, que era valida, tambem nao entrou
    assert service.listar(db, ana, simulado.id, aluno.id) == []


def test_nao_lanca_resposta_para_o_aluno_de_outra_pessoa(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    simulado_da_bia, _ = montar_cenario(db, bia)
    _, aluno_da_ana = montar_cenario(db, ana)

    with pytest.raises(AlunoNaoEncontrado):
        service.lancar(db, bia, simulado_da_bia.id, aluno_da_ana.id, [item(1, Alt.A)])


def test_nao_lanca_resposta_no_simulado_de_outra_pessoa(db):
    ana = criar_usuario(db, "ana@x.com")
    bia = criar_usuario(db, "bia@x.com")
    simulado_da_ana, aluno_da_ana = montar_cenario(db, ana)

    # quem recusa e' o service das questoes, que confere o dono do simulado
    with pytest.raises(QuestaoNaoEncontrada):
        service.lancar(db, bia, simulado_da_ana.id, aluno_da_ana.id, [item(1, Alt.A)])

    assert service.listar(db, ana, simulado_da_ana.id, aluno_da_ana.id) == []


def test_corrigir_conta_acertos_nota_e_acertos_por_componente(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)
    # acertou a 1 (Mat) e a 3 (Port); errou a 2 (Mat)
    service.lancar(db, ana, simulado.id, aluno.id, [item(1, Alt.A), item(2, Alt.E), item(3, Alt.C)])

    resultado = service.corrigir(db, ana, simulado.id, aluno.id)

    assert resultado["aluno_id"] == aluno.id
    assert resultado["simulado_id"] == simulado.id
    assert resultado["total_questoes"] == 3
    assert resultado["total_acertos"] == 2
    assert resultado["nota"] == 6.67
    por_componente = {c["componente"]: (c["acertos"], c["total"]) for c in resultado["acertos_por_componente"]}
    assert por_componente == {Disciplina.MATEMATICA: (1, 2), Disciplina.PORTUGUES: (1, 1)}


def test_corrigir_aluno_sem_respostas_da_nota_zero(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)

    resultado = service.corrigir(db, ana, simulado.id, aluno.id)

    assert resultado["total_acertos"] == 0
    assert resultado["nota"] == 0


def test_corrigir_nao_mistura_respostas_de_outro_simulado(db):
    ana = criar_usuario(db, "ana@x.com")
    simulado, aluno = montar_cenario(db, ana)
    outro = simulados_service.criar(
        db, {"identificacao": "Outro", "data_aplicacao": date(2026, 11, 1), "usuario_id": ana.id}
    )
    questoes_service.criar(
        db, ana, outro.id,
        {"alternativa_correta": Alt.A, "componente_curricular": Disciplina.MATEMATICA, "conteudo": None},
    )
    service.lancar(db, ana, outro.id, aluno.id, [item(1, Alt.A)])

    resultado = service.corrigir(db, ana, simulado.id, aluno.id)

    assert resultado["total_questoes"] == 3
    assert resultado["total_acertos"] == 0


def test_corrigir_simulado_inexistente(db):
    ana = criar_usuario(db, "ana@x.com")
    _, aluno = montar_cenario(db, ana)

    with pytest.raises(SimuladoNaoEncontrado):
        service.corrigir(db, ana, 999, aluno.id)
