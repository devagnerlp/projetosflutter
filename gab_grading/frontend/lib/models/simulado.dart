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
  String get dataFormatada => formatarData(dataAplicacao);
}

String _doisDigitos(int numero) => numero.toString().padLeft(2, '0');

// A data como a pessoa lê e escreve: dd/mm/aaaa.
String formatarData(DateTime data) {
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';
}

// A data como a API espera no JSON: aaaa-mm-dd.
String dataParaApi(DateTime data) {
  return '${data.year}-${_doisDigitos(data.month)}-${_doisDigitos(data.day)}';
}

// Lê o que a pessoa digitou (dd/mm/aaaa). Devolve null se não for uma data de
// verdade: letras, partes faltando, ou um dia que não existe, como 31/02. O
// DateTime "arruma" o 31/02 para março sozinho, por isso o dia, o mês e o ano
// são conferidos de volta.
DateTime? lerData(String texto) {
  final partes = texto.trim().split('/');
  if (partes.length != 3 || partes[2].length != 4) {
    return null;
  }
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null) {
    return null;
  }
  final data = DateTime(ano, mes, dia);
  if (data.day != dia || data.month != mes || data.year != ano) {
    return null;
  }
  return data;
}
