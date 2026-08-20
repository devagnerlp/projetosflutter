import 'questao.dart';

enum StatusResultados {
  bloqueados,
  liberados,
}

class Simulado {
  final String id;
  String titulo;
  String disciplina;
  String turma;
  DateTime dataAplicacao;
  String descricao;
  String professorResponsavel;
  int respostasRecebidas;
  StatusResultados status;
  List<Questao> questoes;

  Simulado({
    required this.id,
    required this.titulo,
    required this.disciplina,
    required this.turma,
    required this.dataAplicacao,
    required this.descricao,
    required this.professorResponsavel,
    required this.respostasRecebidas,
    required this.status,
    required this.questoes,
  });

  int get quantidadeQuestoes => questoes.length;

  Simulado copy() {
    return Simulado(
      id: id,
      titulo: titulo,
      disciplina: disciplina,
      turma: turma,
      dataAplicacao: dataAplicacao,
      descricao: descricao,
      professorResponsavel: professorResponsavel,
      respostasRecebidas: respostasRecebidas,
      status: status,
      questoes: questoes.map((questao) => questao.copy()).toList(),
    );
  }
}