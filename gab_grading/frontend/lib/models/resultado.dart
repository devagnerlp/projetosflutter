// Os acertos de um aluno em um componente curricular (RN-20).
class AcertosDoComponente {
  AcertosDoComponente({
    required this.componente,
    required this.acertos,
    required this.total,
  });

  final String componente;
  final int acertos;
  final int total;

  factory AcertosDoComponente.fromJson(Map<String, dynamic> json) {
    return AcertosDoComponente(
      componente: json['componente'],
      acertos: json['acertos'],
      total: json['total'],
    );
  }
}

// A correção de um aluno em um simulado, como a API a calcula.
class Resultado {
  Resultado({
    required this.totalQuestoes,
    required this.totalAcertos,
    required this.nota,
    required this.porComponente,
  });

  final int totalQuestoes;
  final int totalAcertos;
  final double nota; // de 0 a 10
  final List<AcertosDoComponente> porComponente;

  factory Resultado.fromJson(Map<String, dynamic> json) {
    return Resultado(
      totalQuestoes: json['total_questoes'],
      totalAcertos: json['total_acertos'],
      // O JSON pode trazer 10 ou 10.0: num cobre os dois.
      nota: (json['nota'] as num).toDouble(),
      porComponente: [
        for (final item in json['acertos_por_componente'])
          AcertosDoComponente.fromJson(item),
      ],
    );
  }
}
