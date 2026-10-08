import 'package:flutter/material.dart';

import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'telas/cadastro_screen.dart';
import 'telas/inicio_screen.dart';
import 'telas/login_screen.dart';
import 'services/sessao_service.dart';
import 'widgets/rota_protegida.dart';

// Aqui as camadas se montam, como o main.py monta a API no backend:
// o repositório entra no service, e o service entra nas telas.
void main() {
  final sessao = SessaoService(UsuarioRepository());
  runApp(GabGradingApp(sessao: sessao));
}

class GabGradingApp extends StatelessWidget {
  const GabGradingApp({super.key, required this.sessao});

  final SessaoService sessao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabGrading',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => LoginScreen(sessao: sessao),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => RotaProtegida(
          sessao: sessao,
          tela: InicioScreen(sessao: sessao),
        ),
      },
    );
  }
}
