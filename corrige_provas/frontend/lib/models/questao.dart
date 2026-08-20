class Questao {
  int numero;
  String? gabarito;
  String assunto;

  Questao({
    required this.numero,
    this.gabarito,
    this.assunto = '',
  });

  Questao copy() {
    return Questao(
      numero: numero,
      gabarito: gabarito,
      assunto: assunto,
    );
  }
}