import '../models/resultado.dart';
import '../repositories/correcao_repository.dart';
import 'sessao_service.dart';
import 'traducao.dart';

// As respostas dos alunos e a correção. Não guarda estado.
class CorrecaoService {
  CorrecaoService(this.repositorio, this.sessao);

  final CorrecaoRepository repositorio;
  final SessaoService sessao;

  String get _token => sessao.token!;

  Future<Map<int, String>> respostas(int simuladoId, int alunoId) {
    return traduzir(() => repositorio.respostas(_token, simuladoId, alunoId));
  }

  Future<void> lancar(int simuladoId, int alunoId, Map<int, String> escolhas) {
    return traduzir(() => repositorio.lancar(_token, simuladoId, alunoId, escolhas));
  }

  Future<Resultado> resultado(int simuladoId, int alunoId) {
    return traduzir(() => repositorio.resultado(_token, simuladoId, alunoId));
  }
}
