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
      throw ErroDeSimulados('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }

  // Um simulado só, pelo id: as mesmas regras do listar.
  Future<Simulado> buscar(int id) async {
    try {
      return await repositorio.buscar(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeSimulados(e.mensagem);
    } on Exception {
      throw ErroDeSimulados('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }
}
