from ..database import conectar

ATIVO = "ativo"

class Questao:
    def __init__(self, id, simulado_id, numero, gabarito, area_conhecimento, assunto):
        self.id = id
        self.simulado_id = simulado_id
        self.numero = numero
        self.gabarito = gabarito
        self.area_conhecimento = area_conhecimento
        self.assunto = assunto

class RepositorioSQLite:
    def __init__(self, banco):
        self.banco = banco

    def listar_questoes(self, simulado_id):
        """Retorna todas as questões do simulado."""
        conn = conectar(self.banco)
        try:
            linhas = conn.execute(
                "SELECT * FROM questoes WHERE simulado_id = ?", 
                (simulado_id,)).fetchall()           
        finally:
            conn.close()

        return [
            Questao(
                linha["id"],
                linha["simulado_id"],
                linha["numero"],
                linha["gabarito"],
                linha["area_conhecimento"],
                linha["assunto"]
            )
        for linha in linhas
        ]