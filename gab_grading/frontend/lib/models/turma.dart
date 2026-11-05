// A turma como o app a conhece: o TurmaPublica da API, sem o que o app não usa.
class Turma {
  Turma({required this.id, required this.nome});

  final int id;
  final String nome;

  // {"id": 1, "nome": "3o ano A", "ativo": true}
  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(id: json['id'], nome: json['nome']);
  }
}
