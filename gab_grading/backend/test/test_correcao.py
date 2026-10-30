import pytest

from app.respostas.correcao import calcular_resultado

# O gabarito: (numero_questao, alternativa_correta, componente).
GABARITO = [
    (1, "A", "MATEMATICA"),
    (2, "B", "MATEMATICA"),
    (3, "C", "PORTUGUES"),
    (4, "D", "PORTUGUES"),
]


def test_todas_certas_da_nota_maxima():
    marcadas = {1: "A", 2: "B", 3: "C", 4: "D"}

    resultado = calcular_resultado(GABARITO, marcadas)

    assert resultado["total_acertos"] == 4
    assert resultado["total_questoes"] == 4
    assert resultado["nota"] == 10


def test_todas_erradas_da_nota_zero():
    marcadas = {1: "E", 2: "E", 3: "E", 4: "E"}

    resultado = calcular_resultado(GABARITO, marcadas)

    assert resultado["total_acertos"] == 0
    assert resultado["nota"] == 0


def test_a_nota_e_proporcional_aos_acertos():
    marcadas = {1: "A", 2: "B", 3: "E", 4: "E"}   # 2 de 4

    assert calcular_resultado(GABARITO, marcadas)["nota"] == 5


def test_questao_em_branco_conta_como_erro():
    marcadas = {1: "A"}   # as outras tres ficaram em branco

    resultado = calcular_resultado(GABARITO, marcadas)

    assert resultado["total_acertos"] == 1
    assert resultado["total_questoes"] == 4


def test_a_nota_e_arredondada_em_duas_casas():
    gabarito = [(1, "A", "MATEMATICA"), (2, "B", "MATEMATICA"), (3, "C", "MATEMATICA")]

    resultado = calcular_resultado(gabarito, {1: "A"})   # 1 de 3 = 3,333...

    assert resultado["nota"] == 3.33


def test_acertos_por_componente():
    marcadas = {1: "A", 2: "E", 3: "C", 4: "D"}   # Matematica 1 de 2; Portugues 2 de 2

    por_componente = calcular_resultado(GABARITO, marcadas)["acertos_por_componente"]

    assert por_componente == [
        {"componente": "MATEMATICA", "acertos": 1, "total": 2},
        {"componente": "PORTUGUES", "acertos": 2, "total": 2},
    ]


def test_resposta_de_questao_que_nao_existe_no_gabarito_e_ignorada():
    marcadas = {1: "A", 2: "B", 3: "C", 4: "D", 99: "A"}

    resultado = calcular_resultado(GABARITO, marcadas)

    assert resultado["total_questoes"] == 4
    assert resultado["total_acertos"] == 4


def test_simulado_sem_questoes_da_nota_zero_sem_dividir_por_zero():
    resultado = calcular_resultado([], {})

    assert resultado["total_questoes"] == 0
    assert resultado["nota"] == 0
    assert resultado["acertos_por_componente"] == []


@pytest.mark.parametrize("acertos, nota", [(0, 0), (1, 2.5), (2, 5), (3, 7.5), (4, 10)])
def test_nota_em_cada_faixa_de_acertos(acertos, nota):
    certas = {1: "A", 2: "B", 3: "C", 4: "D"}
    marcadas = {n: letra for n, letra in list(certas.items())[:acertos]}

    assert calcular_resultado(GABARITO, marcadas)["nota"] == nota
