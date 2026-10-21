// O simulado como o app o conhece: o mesmo SimuladoPublico que a API devolve.
class Simulado {
  Simulado({
    required this.id,
    required this.identificacao,
    required this.dataAplicacao,
    required this.ativo,
  });

  final int id;
  final String identificacao;
  final DateTime dataAplicacao;
  final bool ativo;

  // Monta um Simulado a partir de um item do JSON da API:
  // {"id": 1, "identificacao": "ENEM 2025", "data_aplicacao": "2025-11-09", ...}.
  // O que o app não usa (o usuario_id) fica de fora. A data chega como texto
  // 'aaaa-mm-dd', e o DateTime.parse a transforma numa data de verdade.
  factory Simulado.fromJson(Map<String, dynamic> json) {
    return Simulado(
      id: json['id'],
      identificacao: json['identificacao'],
      dataAplicacao: DateTime.parse(json['data_aplicacao']),
      ativo: json['ativo'],
    );
  }

  // A data como a pessoa lê: dd/mm/aaaa.
  String get dataFormatada {
    final dia = dataAplicacao.day.toString().padLeft(2, '0');
    final mes = dataAplicacao.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dataAplicacao.year}';
  }
}
