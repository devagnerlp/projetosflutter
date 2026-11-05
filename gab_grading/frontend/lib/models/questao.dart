// A questão de um simulado, com a alternativa certa (o gabarito).
class Questao {
  Questao({
    required this.id,
    required this.numero,
    required this.alternativaCorreta,
    required this.componente,
    this.conteudo,
  });

  final int id;
  final int numero;
  final String alternativaCorreta;
  final String componente;
  final String? conteudo;

  // {"id": 1, "numero_questao": 1, "alternativa_correta": "A",
  //  "componente_curricular": "MATEMÁTICA", "conteudo": null, "simulado_id": 1}
  factory Questao.fromJson(Map<String, dynamic> json) {
    return Questao(
      id: json['id'],
      numero: json['numero_questao'],
      alternativaCorreta: json['alternativa_correta'],
      componente: json['componente_curricular'],
      conteudo: json['conteudo'],
    );
  }
}
