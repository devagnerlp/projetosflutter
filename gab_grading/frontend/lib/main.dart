import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/simulado.dart';
import 'repositories/simulado_repository.dart';
import 'repositories/token_repository.dart';
import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'telas/cadastro_screen.dart';
import 'telas/formulario_screen.dart';
import 'telas/inicio_screen.dart';
import 'telas/login_screen.dart';
import 'telas/perfil_screen.dart';
import 'telas/simulado_screen.dart';
import 'telas/simulados_screen.dart';
import 'services/sessao_service.dart';
import 'services/simulado_service.dart';
import 'widgets/rota_protegida.dart';

// Aqui as camadas se montam, como o main.py monta a API no backend: os
// repositórios entram nos services, e os services ficam no topo do app, onde
// toda tela os alcança, sem passar de construtor em construtor.
Future<void> main() async {
  // O Flutter precisa estar de pé antes de qualquer pacote falar com o aparelho.
  WidgetsFlutterBinding.ensureInitialized();
  final sessao = SessaoService(UsuarioRepository(), tokens: TokenRepository());
  // Antes de a primeira tela aparecer: se o aparelho guardou um token que a
  // API ainda aceita, a sessão volta e o app abre logado.
  await sessao.restaurar();
  // O service dos simulados pega o token na sessão: nasce com ela na mão.
  final simulados = SimuladoService(SimuladoRepository(), sessao);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessao),
        Provider.value(value: simulados),
      ],
      child: const GabGradingApp(),
    ),
  );
}

class GabGradingApp extends StatelessWidget {
  const GabGradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabGrading',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.inicio,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => const RotaProtegida(tela: InicioScreen()),
        AppRoutes.simulados: (context) => const RotaProtegida(tela: SimuladosScreen()),
        // O detalhe: a rota entrega à tela o id que veio nos arguments.
        AppRoutes.simulado: (context) => RotaProtegida(
          tela: SimuladoScreen(id: ModalRoute.of(context)!.settings.arguments as int?),
        ),
        // O formulário: com um simulado nos arguments, edita; sem, cria.
        AppRoutes.formulario: (context) => RotaProtegida(
          tela: FormularioScreen(
            simulado: ModalRoute.of(context)!.settings.arguments as Simulado?,
          ),
        ),
        AppRoutes.perfil: (context) => const RotaProtegida(tela: PerfilScreen()),
      },
    );
  }
}
