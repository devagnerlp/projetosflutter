import 'package:http/http.dart' as http;

import '../models/questao.dart';
import 'api_cliente.dart';

// As questões de um simulado: o único lugar que sabe os caminhos
// /simulados/{id}/questoes. A questão não tem DELETE: a API não deixa excluir
// uma questão isolada (RN-13), pelo efeito dela na nota.
class QuestaoRepository {
  QuestaoRepository({http.Client? cliente}) : api = ApiCliente(cliente ?? http.Client());

  final ApiCliente api;

  Future<List<Questao>> listar(String token, int simuladoId) async {
    final itens = await api.pedir('GET', '/simulados/$simuladoId/questoes/', token);
    return [for (final item in itens) Questao.fromJson(item)];
  }

  // O número da questão não vai: quem o atribui é a API, em sequência (RN-12).
  Future<Questao> criar(
    String token,
    int simuladoId,
    String alternativa,
    String componente,
    String? conteudo,
  ) async {
    final item = await api.pedir(
      'POST',
      '/simulados/$simuladoId/questoes/',
      token,
      corpo: {
        'alternativa_correta': alternativa,
        'componente_curricular': componente,
        'conteudo': conteudo,
      },
      esperado: 201,
    );
    return Questao.fromJson(item);
  }

  Future<Questao> atualizar(
    String token,
    int simuladoId,
    int id,
    String alternativa,
    String componente,
    String? conteudo,
  ) async {
    final item = await api.pedir(
      'PATCH',
      '/simulados/$simuladoId/questoes/$id',
      token,
      corpo: {
        'alternativa_correta': alternativa,
        'componente_curricular': componente,
        'conteudo': conteudo,
      },
    );
    return Questao.fromJson(item);
  }
}
