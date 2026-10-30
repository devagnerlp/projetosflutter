"""A conta da correcao, e mais nada.

Uma funcao que recebe valores e devolve a resposta: sem banco, sem HTTP, sem
`print`. Quem busca os dados e' o service; aqui so' se confere e se conta.
Por isso ela se testa com listas e dicionarios, sem montar nada.
"""

NOTA_MAXIMA = 10


def calcular_resultado(gabarito, marcadas):
    """Compara o gabarito com o que o aluno marcou.

    gabarito: lista de (numero_questao, alternativa_correta, componente).
    marcadas: dict {numero_questao: alternativa_marcada}. Questao em branco
              (sem chave no dict) conta como erro.

    Devolve total_questoes, total_acertos, nota (0 a 10, duas casas) e os
    acertos por componente curricular (RN-20), na ordem em que aparecem.
    """
    por_componente = {}
    total_acertos = 0
    for numero, correta, componente in sorted(gabarito, key=lambda q: q[0]):
        contadores = por_componente.setdefault(componente, {"acertos": 0, "total": 0})
        contadores["total"] += 1
        if marcadas.get(numero) == correta:
            contadores["acertos"] += 1
            total_acertos += 1

    total_questoes = len(gabarito)
    nota = round(total_acertos / total_questoes * NOTA_MAXIMA, 2) if total_questoes else 0.0
    return {
        "total_questoes": total_questoes,
        "total_acertos": total_acertos,
        "nota": nota,
        "acertos_por_componente": [
            {"componente": nome, **contadores}
            for nome, contadores in por_componente.items()
        ],
    }
