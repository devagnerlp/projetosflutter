import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/aluno.dart';
import 'models/questao.dart';
import 'models/simulado.dart';
import 'models/turma.dart';
import 'repositories/correcao_repository.dart';
import 'repositories/questao_repository.dart';
import 'repositories/simulado_repository.dart';
import 'repositories/token_repository.dart';
import 'repositories/turma_repository.dart';
import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'telas/aluno_formulario_screen.dart';
import 'telas/cadastro_screen.dart';
import 'telas/correcao_screen.dart';
import 'telas/formulario_screen.dart';
import 'telas/inicio_screen.dart';
import 'telas/login_screen.dart';
import 'telas/perfil_screen.dart';
import 'telas/questao_formulario_screen.dart';
import 'telas/questoes_screen.dart';
import 'telas/respostas_screen.dart';
import 'telas/resultado_screen.dart';
import 'telas/simulado_screen.dart';
import 'telas/simulados_screen.dart';
import 'telas/turma_formulario_screen.dart';
import 'telas/turma_screen.dart';
import 'telas/turmas_screen.dart';
import 'services/correcao_service.dart';
import 'services/questao_service.dart';
import 'services/sessao_service.dart';
import 'services/simulado_service.dart';
import 'services/turma_service.dart';
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
  // Os services pegam o token na sessão: nascem com ela na mão.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessao),
        Provider.value(value: SimuladoService(SimuladoRepository(), sessao)),
        Provider.value(value: QuestaoService(QuestaoRepository(), sessao)),
        Provider.value(value: TurmaService(TurmaRepository(), sessao)),
        Provider.value(value: CorrecaoService(CorrecaoRepository(), sessao)),
      ],
      child: const GabGradingApp(),
    ),
  );
}

// O que a rota entrega a uma tela que precisa de dados nos arguments (o id de um
// simulado, um aluno...). Sem eles (um F5 apaga os arguments, que moram na
// memória), a tela de detalhe não tem o que mostrar, e a rota abre a `lista`.
Widget _comArgumentos<T>(BuildContext context, Widget Function(T argumentos) tela, Widget lista) {
  final argumentos = ModalRoute.of(context)!.settings.arguments;
  return RotaProtegida(tela: argumentos is T ? tela(argumentos) : lista);
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
        AppRoutes.questoes: (context) => _comArgumentos<int>(
          context,
          (simuladoId) => QuestoesScreen(simuladoId: simuladoId),
          const SimuladosScreen(),
        ),
        AppRoutes.questaoFormulario: (context) => _comArgumentos<({int simuladoId, Questao? questao})>(
          context,
          (args) => QuestaoFormularioScreen(simuladoId: args.simuladoId, questao: args.questao),
          const SimuladosScreen(),
        ),
        AppRoutes.turmas: (context) => const RotaProtegida(tela: TurmasScreen()),
        AppRoutes.turma: (context) => _comArgumentos<int>(
          context,
          (id) => TurmaScreen(id: id),
          const TurmasScreen(),
        ),
        // O formulário da turma: com uma turma nos arguments, edita; sem, cria.
        AppRoutes.turmaFormulario: (context) => RotaProtegida(
          tela: TurmaFormularioScreen(
            turma: ModalRoute.of(context)!.settings.arguments as Turma?,
          ),
        ),
        AppRoutes.alunoFormulario: (context) => _comArgumentos<({int turmaId, Aluno? aluno})>(
          context,
          (args) => AlunoFormularioScreen(turmaId: args.turmaId, aluno: args.aluno),
          const TurmasScreen(),
        ),
        AppRoutes.correcao: (context) => _comArgumentos<int>(
          context,
          (simuladoId) => CorrecaoScreen(simuladoId: simuladoId),
          const SimuladosScreen(),
        ),
        AppRoutes.respostas: (context) => _comArgumentos<({int simuladoId, Aluno aluno})>(
          context,
          (args) => RespostasScreen(simuladoId: args.simuladoId, aluno: args.aluno),
          const SimuladosScreen(),
        ),
        AppRoutes.resultado: (context) => _comArgumentos<({int simuladoId, Aluno aluno})>(
          context,
          (args) => ResultadoScreen(simuladoId: args.simuladoId, aluno: args.aluno),
          const SimuladosScreen(),
        ),
        AppRoutes.perfil: (context) => const RotaProtegida(tela: PerfilScreen()),
      },
    );
  }
}
