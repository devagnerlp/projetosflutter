import pytest
from pydantic import ValidationError

from app.alunos.schemas import AlunoAtualizar, AlunoCriar
from app.turma.schema import TurmaAtualizar, TurmaCriar

# As regras do nome de uma turma e de um aluno, como valem HOJE: pelo menos 2
# caracteres (sem contar os espacos das pontas), no maximo 120 (o tamanho da
# coluna no banco) e sem espacos sobrando. Valem igual para a turma e o aluno.
CRIAR = [TurmaCriar, AlunoCriar]
ATUALIZAR = [TurmaAtualizar, AlunoAtualizar]


def recusas(schema, nome):
    with pytest.raises(ValidationError) as erro:
        schema(nome=nome)
    return erro.value.errors()


@pytest.mark.parametrize("schema", CRIAR)
def test_nome_com_dois_caracteres_e_aceito(schema):
    assert schema(nome="AB").nome == "AB"


@pytest.mark.parametrize("schema", CRIAR)
def test_nome_com_um_caractere_e_recusado_com_a_frase_do_minimo(schema):
    erros = recusas(schema, "A")

    assert erros[0]["msg"] == "Value error, O nome precisa ter pelo menos 2 caracteres"


@pytest.mark.parametrize("schema", CRIAR)
def test_nome_so_com_espacos_e_recusado(schema):
    erros = recusas(schema, "     ")

    assert erros[0]["msg"] == "Value error, O nome precisa ter pelo menos 2 caracteres"


@pytest.mark.parametrize("schema", CRIAR)
def test_os_espacos_das_pontas_saem_e_nao_contam(schema):
    assert schema(nome="  Bruno  ").nome == "Bruno"
    recusas(schema, "  A  ")  # sobra 1 caractere: recusado


@pytest.mark.parametrize("schema", CRIAR)
def test_nome_de_120_caracteres_e_aceito_e_de_121_e_recusado(schema):
    assert len(schema(nome="a" * 120).nome) == 120

    erros = recusas(schema, "a" * 121)

    assert erros[0]["type"] == "string_too_long"
    assert erros[0]["ctx"] == {"max_length": 120}


@pytest.mark.parametrize("schema", ATUALIZAR)
def test_na_edicao_o_nome_e_opcional_mas_tem_as_mesmas_regras(schema):
    assert schema().nome is None
    assert schema(nome=" Novo ").nome == "Novo"
    assert recusas(schema, "A")[0]["msg"] == "Value error, O nome precisa ter pelo menos 2 caracteres"
    assert recusas(schema, "a" * 121)[0]["type"] == "string_too_long"
