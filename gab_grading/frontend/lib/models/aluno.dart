// O aluno como o app o conhece: o AlunoPublico da API. Todo aluno é de uma turma.
class Aluno {
  Aluno({required this.id, required this.nome, required this.turmaId});

  final int id;
  final String nome;
  final int turmaId;

  // {"id": 1, "nome": "Bruno", "turma_id": 1, "ativo": true}
  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(id: json['id'], nome: json['nome'], turmaId: json['turma_id']);
  }
}
