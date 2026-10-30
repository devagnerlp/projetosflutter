import 'package:http/http.dart' as http;

import '../models/resultado.dart';
import 'api_cliente.dart';

// As respostas de um aluno em um simulado e a correção delas.
class CorrecaoRepository {
  CorrecaoRepository({http.Client? cliente}) : api = ApiCliente(cliente ?? http.Client());

  final ApiCliente api;

  String _base(int simuladoId, int alunoId) => '/simulados/$simuladoId/alunos/$alunoId';

  // O que o aluno marcou: número da questão -> letra. Questão sem chave está
  // em branco.
  Future<Map<int, String>> respostas(String token, int simuladoId, int alunoId) async {
    final itens = await api.pedir('GET', '${_base(simuladoId, alunoId)}/respostas', token);
    return {
      for (final item in itens) item['numero_questao'] as int: item['alternativa_escolhida'] as String,
    };
  }

  // PUT: o gabarito do aluno vai por inteiro e SUBSTITUI o anterior. A questão
  // que não for na lista fica em branco.
  Future<void> lancar(String token, int simuladoId, int alunoId, Map<int, String> escolhas) async {
    await api.pedir(
      'PUT',
      '${_base(simuladoId, alunoId)}/respostas',
      token,
      corpo: {
        'respostas': [
          for (final e in escolhas.entries) {'numero_questao': e.key, 'alternativa': e.value},
        ],
      },
    );
  }

  // A correção: a API calcula na hora, o app só mostra.
  Future<Resultado> resultado(String token, int simuladoId, int alunoId) async {
    final item = await api.pedir('GET', '${_base(simuladoId, alunoId)}/resultado', token);
    return Resultado.fromJson(item);
  }
}
