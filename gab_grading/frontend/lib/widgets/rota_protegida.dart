import 'package:flutter/material.dart';

import '../telas/login_screen.dart';
import '../services/sessao_service.dart';

// O guarda de uma rota: com sessão, mostra a tela; sem sessão, mostra o login.
class RotaProtegida extends StatelessWidget {
  const RotaProtegida({super.key, required this.sessao, required this.tela});
  final SessaoService sessao;
  final Widget tela;
  @override
  Widget build(BuildContext context) {
    return sessao.token != null ? tela : LoginScreen(sessao: sessao);
  }
}
