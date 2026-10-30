import 'package:http/http.dart' as http;

import '../models/aluno.dart';
import '../models/turma.dart';
import 'api_cliente.dart';

// As turmas e os alunos delas: o único lugar que sabe os caminhos /turmas.
// O aluno nunca existe fora de uma turma, então os dois moram juntos.
class TurmaRepository {
  TurmaRepository({http.Client? cliente}) : api = ApiCliente(cliente ?? http.Client());

  final ApiCliente api;

  Future<List<Turma>> listar(String token) async {
    final itens = await api.pedir('GET', '/turmas/', token);
    return [for (final item in itens) Turma.fromJson(item)];
  }

  Future<Turma> buscar(String token, int id) async {
    return Turma.fromJson(await api.pedir('GET', '/turmas/$id', token));
  }

  Future<Turma> criar(String token, String nome) async {
    final item = await api.pedir('POST', '/turmas/', token, corpo: {'nome': nome}, esperado: 201);
    return Turma.fromJson(item);
  }

  Future<Turma> atualizar(String token, int id, String nome) async {
    final item = await api.pedir('PATCH', '/turmas/$id', token, corpo: {'nome': nome});
    return Turma.fromJson(item);
  }

  Future<void> excluir(String token, int id) async {
    await api.pedir('DELETE', '/turmas/$id', token, esperado: 204);
  }

  // Os alunos de uma turma.
  Future<List<Aluno>> listarAlunos(String token, int turmaId) async {
    final itens = await api.pedir('GET', '/turmas/$turmaId/alunos/', token);
    return [for (final item in itens) Aluno.fromJson(item)];
  }

  Future<Aluno> criarAluno(String token, int turmaId, String nome) async {
    final item = await api.pedir(
      'POST',
      '/turmas/$turmaId/alunos/',
      token,
      corpo: {'nome': nome},
      esperado: 201,
    );
    return Aluno.fromJson(item);
  }

  Future<Aluno> atualizarAluno(String token, int turmaId, int id, String nome) async {
    final item = await api.pedir(
      'PATCH',
      '/turmas/$turmaId/alunos/$id',
      token,
      corpo: {'nome': nome},
    );
    return Aluno.fromJson(item);
  }

  Future<void> excluirAluno(String token, int turmaId, int id) async {
    await api.pedir('DELETE', '/turmas/$turmaId/alunos/$id', token, esperado: 204);
  }
}
