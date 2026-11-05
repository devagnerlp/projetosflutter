import '../repositories/usuario_repository.dart';

// A recusa de qualquer service que não tem erro próprio, com a frase que a tela
// mostra. Os services de turma, aluno, questão e correção usam esta.
class ErroDeApi implements Exception {
  ErroDeApi(this.mensagem);

  final String mensagem;

  // O texto do erro quando a tela o mostra: é o __str__ do Python.
  @override
  String toString() => mensagem;
}

const semApi = 'Não consegui falar com a API. O uvicorn está rodando?';

// Roda a chamada ao repositório e traduz o que der errado: a recusa da API
// (404, 422...) vira a frase dela, e uma falha de fora, como a rede (o uvicorn
// parado), vira `semApi`. Um erro do próprio código não é Exception: passa
// direto, e a tela o mostra inteiro.
Future<T> traduzir<T>(Future<T> Function() chamada) async {
  try {
    return await chamada();
  } on ErroDeApi {
    rethrow;
  } on RecusaDaApi catch (e) {
    throw ErroDeApi(e.mensagem);
  } on Exception {
    throw ErroDeApi(semApi);
  }
}
