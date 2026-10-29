import pytest

from app.simulados.divisao_area import (
    DivisaoPorFaixa,
    DivisaoPorListaExplicita,
    DivisaoUnica,
    divisao_para,
)
from app.simulados.erros import AreaNaoEncontrada, TipoDeDivisaoDesconhecido

def test_faixa_devolve_a_area_da_questao():
    # preparar: Matemática vai de 1 a 10, Ciências de 11 a 20
    divisao = DivisaoPorFaixa([("Matemática", 1, 10), ("Ciências", 11, 20)])

    # executar e conferir
    assert divisao.area_da_questao(5) == "Matemática"
    assert divisao.area_da_questao(15) == "Ciências"

@pytest.mark.parametrize(
    "questao, area_esperada",
    [(1, "Matemática"), (10, "Matemática"), (11, "Ciências"), (20, "Ciências")],
)
def test_faixa_nos_limites_parametrizado(questao, area_esperada):
    divisao = DivisaoPorFaixa([("Matemática", 1, 10), ("Ciências", 11, 20)])

    assert divisao.area_da_questao(questao) == area_esperada

def test_faixa_nos_limites():
    # preparar: Matemática vai de 1 a 10, Ciências de 11 a 20
    divisao = DivisaoPorFaixa([("Matemática", 1, 10), ("Ciências", 11, 20)])

    # executar e conferir
    assert divisao.area_da_questao(1) == "Matemática"   # primeira da faixa
    assert divisao.area_da_questao(10) == "Matemática"  # última da faixa
    assert divisao.area_da_questao(11) == "Ciências"    # primeira da seguinte
    assert divisao.area_da_questao(20) == "Ciências"    # última da seguinte
    
@pytest.mark.parametrize("questao", [0, 21])
def test_faixa_recusa_questao_fora_de_qualquer_faixa(questao):
    divisao = DivisaoPorFaixa([("Matemática", 1, 10), ("Ciências", 11, 20)])

    with pytest.raises(AreaNaoEncontrada):
        divisao.area_da_questao(questao)

def test_lista_explicita_devolve_a_area_de_cada_questao():
    # áreas embaralhadas: não existe faixa que resolva isso
    divisao = DivisaoPorListaExplicita({1: "Geografia", 2: "Sociologia", 3: "Geografia"})

    assert divisao.area_da_questao(1) == "Geografia"
    assert divisao.area_da_questao(2) == "Sociologia"
    assert divisao.area_da_questao(3) == "Geografia"


def test_lista_explicita_recusa_questao_que_nao_esta_no_mapa():
    divisao = DivisaoPorListaExplicita({1: "Geografia"})

    with pytest.raises(AreaNaoEncontrada):
        divisao.area_da_questao(2)


def test_unica_devolve_sempre_a_mesma_area():
    divisao = DivisaoUnica("Matemática")

    assert divisao.area_da_questao(1) == "Matemática"
    assert divisao.area_da_questao(999) == "Matemática"

def test_fabrica_monta_a_divisao_do_tipo_pedido():
    assert isinstance(divisao_para("faixa", [("Matemática", 1, 10)]), DivisaoPorFaixa)
    assert isinstance(divisao_para("lista_explicita", {1: "Geografia"}), DivisaoPorListaExplicita)
    assert isinstance(divisao_para("unica", "Matemática"), DivisaoUnica)


def test_fabrica_recusa_tipo_desconhecido():
    with pytest.raises(TipoDeDivisaoDesconhecido):
        divisao_para("inventado", None)