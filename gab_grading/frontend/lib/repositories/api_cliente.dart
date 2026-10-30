import 'dart:convert';

import 'package:http/http.dart' as http;

import 'usuario_repository.dart';

// O jeito comum de falar com a API: o endereço, o token no cabeçalho, o JSON de
// ida e de volta, e a recusa. Os repositórios de turma, aluno, questão e
// correção só dizem QUAL pedido fazer; é aqui que ele sai.
class ApiCliente {
  ApiCliente(this.cliente);

  final http.Client cliente;

  // Faz o pedido e devolve o JSON da resposta (ou null, se não veio corpo).
  // `esperado` é o status do sucesso: 200, 201 ou 204. Qualquer outro vira uma
  // RecusaDaApi, com a frase que a API mandou.
  Future<dynamic> pedir(
    String metodo,
    String caminho,
    String token, {
    Object? corpo,
    int esperado = 200,
  }) async {
    final pedido = http.Request(metodo, Uri.parse('$enderecoDaApi$caminho'));
    pedido.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) {
      pedido.headers['Content-Type'] = 'application/json';
      pedido.body = jsonEncode(corpo);
    }
    final resposta = await http.Response.fromStream(await cliente.send(pedido));
    if (resposta.statusCode != esperado) {
      throw RecusaDaApi(resposta.statusCode, fraseDaApi(resposta.body));
    }
    return resposta.body.isEmpty ? null : jsonDecode(resposta.body);
  }
}
