import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/simulado.dart';
import 'usuario_repository.dart';

// O repositório dos simulados: como o do usuário, o único que sabe endereço,
// HTTP e JSON. O endereço da API e a RecusaDaApi vêm do usuario_repository.
class SimuladoRepository {
  SimuladoRepository({http.Client? cliente}) : cliente = cliente ?? http.Client();

  final http.Client cliente;

  // GET /simulados/, com o token no cabeçalho, como o quemSouEu: a API devolve
  // só os simulados do dono do token. A resposta é uma LISTA em JSON, e cada
  // item vira um Simulado.
  Future<List<Simulado>> listar(String token) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/simulados/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, fraseDaApi(resposta.body));
    }
    final itens = jsonDecode(resposta.body);
    return [for (final item in itens) Simulado.fromJson(item)];
  }

  // GET /simulados/{id}: um simulado só, como ele está AGORA no banco. Simulado
  // de outra pessoa, ou que não existe mais, a API responde 404.
  Future<Simulado> buscar(String token, int id) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/simulados/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, fraseDaApi(resposta.body));
    }
    return Simulado.fromJson(jsonDecode(resposta.body));
  }
}
