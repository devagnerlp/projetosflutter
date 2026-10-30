import '../models/simulado.dart';
import '../repositories/simulado_repository.dart';
import '../repositories/usuario_repository.dart';
import 'sessao_service.dart';

// A recusa dos simulados, com a frase que a tela mostra.
class ErroDeSimulados implements Exception {
  ErroDeSimulados(this.mensagem);

  final String mensagem;

  // O texto do erro quando a tela o mostra: é o __str__ do Python.
  @override
  String toString() => mensagem;
}

const _semApi = 'Não consegui falar com a API. O uvicorn está rodando?';

// As regras dos simulados. Não guarda estado (não é um ChangeNotifier): quem
// lembra se está carregando, se deu erro ou qual é a lista é a própria tela.
// O service pega o token na sessão, pede ao repositório e traduz a recusa.
class SimuladoService {
  SimuladoService(this.repositorio, this.sessao);

  final SimuladoRepository repositorio;
  final SessaoService sessao;

  Future<List<Simulado>> listar() async {
    try {
      // O guarda só abre a tela de simulados com sessão: o token nunca é null aqui.
      return await repositorio.listar(sessao.token!);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      // Uma falha de fora, como a rede: a API nem respondeu (o uvicorn parado).
      // Um erro do próprio código não é Exception: passa direto, e a tela o
      // mostra inteiro.
      throw ErroDeSimulados(_semApi);
    }
  }

  // Um simulado só, pelo id: as mesmas regras do listar.
  Future<Simulado> buscar(int id) async {
    try {
      return await repositorio.buscar(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      throw ErroDeSimulados(_semApi);
    }
  }

  // Criar, editar e excluir: o mesmo molde do listar. O token vem da sessão,
  // e a recusa da API (422, 404) vira a frase que a tela mostra.
  Future<Simulado> criar(String identificacao, DateTime data) async {
    try {
      return await repositorio.criar(sessao.token!, identificacao, data);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      throw ErroDeSimulados(_semApi);
    }
  }

  Future<Simulado> atualizar(int id, String identificacao, DateTime data) async {
    try {
      return await repositorio.atualizar(sessao.token!, id, identificacao, data);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      throw ErroDeSimulados(_semApi);
    }
  }

  Future<void> excluir(int id) async {
    try {
      await repositorio.excluir(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      throw ErroDeSimulados(_semApi);
    }
  }
}
