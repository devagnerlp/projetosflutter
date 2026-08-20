from fastapi import FastAPI

# A instancia da aplicacao. O titulo aparece na pagina /docs.
app = FastAPI(title="API do Meu Projeto", version="0.1.0")


# O decorador diz: "esta funcao atende GET na raiz".
@app.get("/")
def raiz():
    # Devolvemos um dicionario. O FastAPI transforma em JSON sozinho.
    return {"mensagem": "A API do meu projeto esta no ar!"}

@app.get("/simulado")
def dadosFicticios():
    return {
        "simulados": [ 
            {
                "id": "1",
                "titulo": "Simulado de Matemática — 1º Bimestre",
                "disciplina": "Matemática",
                "turma": "2º Ano A",
                "data_aplicacao": "2026-03-15",
                "descricao": "Avaliação de revisão para o primeiro bimestre.",
                "professor_responsavel": "Prof. João Silva",
                "respostas_recebidas": 28,
                "status": "bloqueados",
                "questoes": [
                    {"numero": 1, "gabarito": "A", "assunto": "Frações"},
                    {"numero": 2, "gabarito": "C", "assunto": "Porcentagem"},
                    {"numero": 3, "gabarito": "B"},
                    {"numero": 4, "gabarito": "D", "assunto": "Equações"},
                    {"numero": 5, "gabarito": "A", "assunto": "Geometria"},
                    {"numero": 6, "gabarito": "E", "assunto": "Operações"},
                    {"numero": 7, "gabarito": "B", "assunto": "Frações"},
                    {"numero": 8, "gabarito": "C", "assunto": "Álgebra"},
                    {"numero": 9, "gabarito": "D", "assunto": "Medidas"},
                    {"numero": 10, "gabarito": "A", "assunto": "Probabilidade"},
                ],
            },
            {
                "id": "2",
                "titulo": "Revisão de Porcentagem",
                "disciplina": "Matemática",
                "turma": "1º Ano B",
                "data_aplicacao": "2026-03-22",
                "descricao": "Simulado de revisão sobre porcentagem.",
                "professor_responsavel": "Prof. João Silva",
                "respostas_recebidas": 31,
                "status": "liberados",
                "questoes": [
                    {"numero": 1, "gabarito": "B", "assunto": "Porcentagem"},
                    {"numero": 2, "gabarito": "A", "assunto": "Descontos"},
                    {"numero": 3, "gabarito": "D", "assunto": "Acréscimos"},
                    {"numero": 4, "gabarito": "C", "assunto": "Regra de três"},
                    {"numero": 5, "gabarito": "E"},
                    {"numero": 6, "gabarito": "B"},
                    {"numero": 7, "gabarito": "A"},
                    {"numero": 8, "gabarito": "C"},
                ],
            },
            {
                "id": "3",
                "titulo": "Simulado de História Geral",
                "disciplina": "História",
                "turma": "3º Ano A",
                "data_aplicacao": "2026-04-05",
                "descricao": "Revisão de conteúdos de História Geral.",
                "professor_responsavel": "Prof. João Silva",
                "respostas_recebidas": 22,
                "status": "bloqueados",
                "questoes": [
                    {"numero": 1, "gabarito": "C", "assunto": "Antiguidade"},
                    {"numero": 2, "gabarito": "D", "assunto": "Idade Média"},
                    {"numero": 3, "gabarito": "A", "assunto": "Renascimento"},
                    {"numero": 4, "gabarito": "B", "assunto": "Revoluções"},
                    {"numero": 5, "gabarito": "E"},
                    {"numero": 6, "gabarito": "C"},
                    {"numero": 7, "gabarito": "A"},
                    {"numero": 8, "gabarito": "D"},
                    {"numero": 9, "gabarito": "B"},
                    {"numero": 10, "gabarito": "E"},
                    {"numero": 11, "gabarito": "C"},
                    {"numero": 12, "gabarito": "A"},
                    {"numero": 13, "gabarito": "D"},
                    {"numero": 14, "gabarito": "B"},
                    {"numero": 15, "gabarito": "C"},
                ],
            },
        ]
    }
