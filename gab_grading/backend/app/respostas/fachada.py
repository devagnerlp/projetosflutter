"""A fachada das respostas e da correcao (padrao Facade).

Lancar o gabarito de um aluno, ou corrigi-lo, mexe em varias pecas, numa
ordem que importa:

1. as questoes do simulado (o service das questoes confere que o simulado
   existe, esta' ativo e e' do usuario, e devolve o gabarito);
2. o aluno (o service dos alunos confere que ele e' do usuario);
3. as respostas do aluno (o service das respostas grava ou lista);
4. a conta da nota (correcao.py, uma funcao pura).

A fachada guarda essa sequencia num lugar so', e quem usa (a rota) faz uma
chamada so'. Ela NAO decide nada: a regra do gabarito (RN-23) mora no
service das respostas, a conta mora em correcao.py, e quem fala com o banco
continua sendo o repository de cada assunto. Ela so' chama e junta.
"""
from ..alunos import service as alunos_service
from ..questoes import service as questoes_service
from . import correcao
from . import service as respostas_service


class CorrecaoFacade:
    def __init__(self, questoes, alunos, respostas, correcao):
        # As pecas chegam prontas, de fora (veja obter_correcao, no fim do
        # arquivo). A fachada so' guarda cada uma para usar nos metodos.
        self.questoes = questoes
        self.alunos = alunos
        self.respostas = respostas
        self.correcao = correcao

    def _conferir(self, db, usuario, simulado_id, aluno_id):
        # Os passos 1 e 2, que as tres operacoes fazem igual. A ordem importa:
        # primeiro o simulado, depois o aluno.
        questoes = self.questoes.listar(db, usuario, simulado_id)
        aluno = self.alunos.buscar_por_id(db, usuario, aluno_id)
        return aluno, questoes

    def listar(self, db, usuario, simulado_id, aluno_id):
        """O gabarito que o aluno marcou neste simulado."""
        aluno, questoes = self._conferir(db, usuario, simulado_id, aluno_id)
        return self.respostas.listar(db, aluno.id, simulado_id, questoes)

    def lancar(self, db, usuario, simulado_id, aluno_id, itens):
        """Grava o gabarito do aluno, substituindo o anterior, e devolve o que ficou."""
        aluno, questoes = self._conferir(db, usuario, simulado_id, aluno_id)
        self.respostas.gravar(db, aluno.id, simulado_id, questoes, itens)
        return self.respostas.listar(db, aluno.id, simulado_id, questoes)

    def corrigir(self, db, usuario, simulado_id, aluno_id):
        """aluno_id e simulado_id entram, o resultado sai."""
        aluno, questoes = self._conferir(db, usuario, simulado_id, aluno_id)
        # 3. o que o aluno marcou, no formato que a conta espera: {numero: letra}
        marcadas = {
            r["numero_questao"]: r["alternativa_escolhida"]
            for r in self.respostas.listar(db, aluno.id, simulado_id, questoes)
        }
        # 4. a conta, com o gabarito como lista de (numero, letra certa, componente)
        gabarito = [
            (q.numero_questao, q.alternativa_correta, q.componente_curricular)
            for q in questoes
        ]
        resultado = self.correcao.calcular_resultado(gabarito, marcadas)
        return {"aluno_id": aluno.id, "simulado_id": simulado_id, **resultado}


def obter_correcao():
    """Monta a fachada com as pecas de verdade.

    A rota a recebe pelo Depends(obter_correcao), e os testes chamam esta
    mesma funcao. Trocar uma peca (por exemplo, um service novo) mexe so' aqui.
    """
    return CorrecaoFacade(questoes_service, alunos_service, respostas_service, correcao)
