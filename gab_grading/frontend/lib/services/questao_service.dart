import '../models/questao.dart';
import '../repositories/questao_repository.dart';
import 'sessao_service.dart';
import 'traducao.dart';

// As regras das questões de um simulado. Não guarda estado.
class QuestaoService {
  QuestaoService(this.repositorio, this.sessao);

  final QuestaoRepository repositorio;
  final SessaoService sessao;

  String get _token => sessao.token!;

  Future<List<Questao>> listar(int simuladoId) => traduzir(() => repositorio.listar(_token, simuladoId));

  Future<Questao> criar(int simuladoId, String alternativa, String componente, String conteudo) {
    return traduzir(() => repositorio.criar(_token, simuladoId, alternativa, componente, _opcional(conteudo)));
  }

  Future<Questao> atualizar(int simuladoId, int id, String alternativa, String componente, String conteudo) {
    return traduzir(
      () => repositorio.atualizar(_token, simuladoId, id, alternativa, componente, _opcional(conteudo)),
    );
  }

  // O conteúdo é opcional: campo em branco vai como null, e não como "".
  String? _opcional(String texto) => texto.trim().isEmpty ? null : texto.trim();
}
