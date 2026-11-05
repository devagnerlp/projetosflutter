import '../models/aluno.dart';
import '../models/turma.dart';
import '../repositories/turma_repository.dart';
import 'sessao_service.dart';
import 'traducao.dart';

// As regras das turmas e dos alunos. Não guarda estado: quem lembra o que
// mostrar é a tela. Pega o token na sessão e traduz a recusa da API.
class TurmaService {
  TurmaService(this.repositorio, this.sessao);

  final TurmaRepository repositorio;
  final SessaoService sessao;

  String get _token => sessao.token!;

  Future<List<Turma>> listar() => traduzir(() => repositorio.listar(_token));

  Future<Turma> buscar(int id) => traduzir(() => repositorio.buscar(_token, id));

  Future<Turma> criar(String nome) => traduzir(() => repositorio.criar(_token, nome));

  Future<Turma> atualizar(int id, String nome) => traduzir(() => repositorio.atualizar(_token, id, nome));

  Future<void> excluir(int id) => traduzir(() => repositorio.excluir(_token, id));

  Future<List<Aluno>> alunos(int turmaId) => traduzir(() => repositorio.listarAlunos(_token, turmaId));

  Future<Aluno> criarAluno(int turmaId, String nome) => traduzir(() => repositorio.criarAluno(_token, turmaId, nome));

  Future<Aluno> atualizarAluno(int turmaId, int id, String nome) =>
      traduzir(() => repositorio.atualizarAluno(_token, turmaId, id, nome));

  Future<void> excluirAluno(int turmaId, int id) => traduzir(() => repositorio.excluirAluno(_token, turmaId, id));

  // A turma e os alunos dela, num pedido só para a tela de detalhe.
  Future<({Turma turma, List<Aluno> alunos})> detalhe(int id) {
    return traduzir(() async {
      final turma = await repositorio.buscar(_token, id);
      final alunos = await repositorio.listarAlunos(_token, id);
      return (turma: turma, alunos: alunos);
    });
  }

  // Todas as turmas, cada uma com os seus alunos: a tela de correção usa para
  // escolher quem corrigir.
  Future<List<({Turma turma, List<Aluno> alunos})>> turmasComAlunos() {
    return traduzir(() async {
      final turmas = await repositorio.listar(_token);
      return [
        for (final turma in turmas)
          (turma: turma, alunos: await repositorio.listarAlunos(_token, turma.id)),
      ];
    });
  }
}
