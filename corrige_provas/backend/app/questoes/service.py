from .erros import ErroSimuladoNaoEncontrado, ErroCadastroQuestao

class QuestaoService:
    def __init__(self, repositorio):
        self.repositorio = repositorio

    def cadastrar_questao(self, simulado_id, numero, gabarito, area_conhecimento=None, assunto=None):
        try:
            return self.repositorio.cadastrar_questao(simulado_id, numero, gabarito, area_conhecimento, assunto)
        except ErroSimuladoNaoEncontrado:
            raise ErroSimuladoNaoEncontrado(f"Simulado com ID {simulado_id} não encontrado.")
        except Exception as e:
            raise ErroCadastroQuestao(f"Erro ao cadastrar questão: {str(e)}")