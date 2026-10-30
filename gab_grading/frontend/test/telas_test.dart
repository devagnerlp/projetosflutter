import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/models/simulado.dart';
import 'package:frontend/repositories/simulado_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/telas/cadastro_screen.dart';
import 'package:frontend/telas/inicio_screen.dart';
import 'package:frontend/telas/formulario_screen.dart';
import 'package:frontend/telas/simulado_screen.dart';
import 'package:frontend/telas/simulados_screen.dart';
import 'package:frontend/telas/login_screen.dart';
import 'package:frontend/telas/perfil_screen.dart';
import 'package:frontend/services/sessao_service.dart';
import 'package:frontend/services/simulado_service.dart';

// Uma API de mentira, com um banco de mentira (o Map contas): responde como a
// de verdade, sem precisar do uvicorn. A Ana já tem conta, com a senha
// 'segredo123'. O token de cada conta é 'token-de-' e o e-mail dela.
// Ela conta quantos pedidos recebeu, para o teste do service conferir.
int pedidos = 0;

// O parâmetro guardado é o aparelho de mentira: o que o app tinha guardado da
// última vez que rodou. Por padrão, nada. Sem esta linha, o shared_preferences
// não existe no teste, e o login quebra ao guardar o token.
SessaoService sessaoDeMentira({Map<String, Object> guardado = const {}}) {
  SharedPreferences.setMockInitialValues(guardado);
  final contas = {
    'ana@biblioteca.com': {'nome': 'Ana', 'senha': 'segredo123'},
  };
  final cliente = MockClient((pedido) async {
    pedidos++;
    if (pedido.url.path == '/usuarios/' && pedido.method == 'POST') {
      final dados = jsonDecode(pedido.body);
      if (contas.containsKey(dados['email'])) {
        return http.Response(
          '{"detail": "Ja existe uma conta com o e-mail ${dados['email']}"}',
          409,
        );
      }
      if (dados['senha'].length < 6) {
        return http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'senha'],
                'msg': 'String should have at least 6 characters',
              },
            ],
          }),
          422,
        );
      }
      contas[dados['email']] = {'nome': dados['nome'], 'senha': dados['senha']};
      return http.Response(
        jsonEncode({'id': 2, 'nome': dados['nome'], 'email': dados['email']}),
        201,
      );
    }
    if (pedido.url.path == '/usuarios/login') {
      final email = pedido.bodyFields['username'];
      if (contas[email]?['senha'] == pedido.bodyFields['password']) {
        return http.Response(
          jsonEncode({'access_token': 'token-de-$email', 'token_type': 'bearer'}),
          200,
        );
      }
      return http.Response('{"detail": "E-mail ou senha incorretos"}', 401);
    }
    if (pedido.url.path == '/usuarios/eu') {
      final email = (pedido.headers['Authorization'] ?? '').replaceFirst(
        'Bearer token-de-',
        '',
      );
      if (contas.containsKey(email)) {
        return http.Response(
          jsonEncode({'id': 1, 'nome': contas[email]!['nome'], 'email': email}),
          200,
        );
      }
    }
    return http.Response('{"detail": "Token invalido ou vencido"}', 401);
  });
  return SessaoService(UsuarioRepository(cliente: cliente));
}

// Dois simulados da Ana, na forma do SimuladoPublico que a API devolve.
const doisSimulados = [
  {'id': 1, 'identificacao': 'ENEM 2025 - Dia 1', 'data_aplicacao': '2025-11-09', 'usuario_id': 1, 'ativo': true},
  {'id': 2, 'identificacao': 'Simulado de Matemática', 'data_aplicacao': '2026-03-05', 'usuario_id': 1, 'ativo': true},
];

// A API de simulados de mentira: o GET /simulados/ responde com este status e
// este corpo. Como a de verdade, sem o token no cabeçalho ela responde 401. O
// GET /simulados/{id} procura o simulado nos dois da Ana; outro id, 404.
http.Client apiDeSimulados(int status, Object corpo) {
  return MockClient((pedido) async {
    pedidos++;
    if (pedido.headers['Authorization'] == null) {
      return http.Response('{"detail": "Not authenticated"}', 401);
    }
    final id = pedido.url.pathSegments.last; // '' em /simulados/, '2' em /simulados/2
    if (id.isNotEmpty) {
      for (final simulado in doisSimulados) {
        if ('${simulado['id']}' == id) {
          return http.Response(jsonEncode(simulado), 200);
        }
      }
      return http.Response('{"detail": "Simulado $id nao esta no seu acervo"}', 404);
    }
    return http.Response(jsonEncode(corpo), status);
  });
}

// A API de simulados com banco de mentira: a lista MUDA quando o app cria,
// edita ou exclui, como a de verdade. Recusa o que a API recusaria (a
// identificação de menos de 3 letras, 422) e responde 404 a um id que não está
// no acervo. O corpo do último pedido que mudou algo fica em ultimoCorpo.
Map<String, dynamic>? ultimoCorpo;

http.Client acervoDeMentira() {
  final acervo = <Map<String, dynamic>>[for (final s in doisSimulados) {...s}];
  var proximo = 3;
  http.Response recusaCurta() => http.Response(
        jsonEncode({
          'detail': [
            {
              'loc': ['body', 'identificacao'],
              'msg': 'String should have at least 3 characters',
            },
          ],
        }),
        422,
      );
  return MockClient((pedido) async {
    pedidos++;
    if (pedido.headers['Authorization'] == null) {
      return http.Response('{"detail": "Not authenticated"}', 401);
    }
    final id = pedido.url.pathSegments.last; // '' em /simulados/, '2' em /simulados/2
    if (pedido.method == 'POST') {
      final dados = jsonDecode(pedido.body) as Map<String, dynamic>;
      ultimoCorpo = dados;
      if ((dados['identificacao'] as String).length < 3) {
        return recusaCurta();
      }
      final novo = {
        'id': proximo++,
        'identificacao': dados['identificacao'],
        'data_aplicacao': dados['data_aplicacao'],
        'usuario_id': 1,
        'ativo': true,
      };
      acervo.add(novo);
      return http.Response(jsonEncode(novo), 201);
    }
    if (id.isEmpty) {
      return http.Response(jsonEncode(acervo), 200);
    }
    final i = acervo.indexWhere((s) => '${s['id']}' == id);
    if (i < 0) {
      return http.Response('{"detail": "Simulado $id nao esta no seu acervo"}', 404);
    }
    if (pedido.method == 'PATCH') {
      final dados = jsonDecode(pedido.body) as Map<String, dynamic>;
      ultimoCorpo = dados;
      if ((dados['identificacao'] as String).length < 3) {
        return recusaCurta();
      }
      acervo[i] = {...acervo[i], ...dados};
      return http.Response(jsonEncode(acervo[i]), 200);
    }
    if (pedido.method == 'DELETE') {
      acervo.removeAt(i);
      return http.Response('', 204);
    }
    return http.Response(jsonEncode(acervo[i]), 200);
  });
}

// O app de verdade, com os services de mentira no topo, como o main.dart faz.
// O .value entrega ao Provider um objeto que já existe, em vez de criá-lo.
// Sem a API de simulados, a de mentira responde uma lista vazia.
Widget appDeMentira(SessaoService sessao, {http.Client? simulados}) {
  final repositorio = SimuladoRepository(cliente: simulados ?? apiDeSimulados(200, []));
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sessao),
      Provider.value(value: SimuladoService(repositorio, sessao)),
    ],
    child: const GabGradingApp(),
  );
}

Future<void> preencherEEntrar(WidgetTester tester, String senha) async {
  await tester.enterText(find.byType(TextField).at(0), 'ana@biblioteca.com');
  await tester.enterText(find.byType(TextField).at(1), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
  await tester.pumpAndSettle();
}

Future<void> abrirOMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

// Abre o cadastro pelo link do login e preenche os três campos.
Future<void> preencherECadastrar(WidgetTester tester, String email, String senha) async {
  await tester.tap(find.text('Criar uma conta'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'Bia');
  await tester.enterText(find.byType(TextField).at(1), email);
  await tester.enterText(find.byType(TextField).at(2), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar'));
  await tester.pumpAndSettle();
}

// Os campos do formulário, na ordem em que aparecem na tela.
Finder get campoIdentificacao => find.byType(TextFormField).at(0);
Finder get campoData => find.byType(TextFormField).at(1);

// Toca no + da lista e preenche o formulário novo.
Future<void> abrirOFormularioEPreencher(WidgetTester tester, String identificacao, String data) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(campoIdentificacao, identificacao);
  await tester.enterText(campoData, data);
}

Future<void> tocarEmSalvar(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
  await tester.pumpAndSettle();
}

// Abre o detalhe de um simulado da lista, pelo toque.
Future<void> abrirODetalhe(WidgetTester tester, String identificacao) async {
  await tester.tap(find.text(identificacao));
  await tester.pumpAndSettle();
}

// O botão Excluir DENTRO do diálogo (o do detalhe tem o mesmo texto).
Finder get excluirDoDialogo => find.descendant(of: find.byType(AlertDialog), matching: find.text('Excluir'));

// A Ana já entrou (a sessão de mentira, com o token dela) e toca em Ver os simulados.
Future<void> abrirOsSimulados(WidgetTester tester, http.Client simulados) async {
  final sessao = sessaoDeMentira();
  await sessao.entrar('ana@biblioteca.com', 'segredo123');
  await tester.pumpWidget(appDeMentira(sessao, simulados: simulados));
  await tester.tap(find.text('Ver os simulados'));
  await tester.pumpAndSettle();
}

// O que o aparelho de mentira tem guardado como token (ou null).
Future<String?> tokenGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

// Confere que o cadastro foi recusado, com esta frase para a tela.
Matcher recusadoCom(String frase) {
  return throwsA(isA<ErroDeCadastro>().having((e) => e.mensagem, 'mensagem', frase));
}

void main() {
  testWidgets('a tela de login tem e-mail, senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('a tela de cadastro tem nome, e-mail e senha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });

  testWidgets('com a senha certa, a rota /inicio abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherEEntrar(tester, 'segredo123');

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('com a senha errada, fica no login e mostra o erro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherEEntrar(tester, 'senha-errada');

    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o link Criar uma conta abre o cadastro pelo nome da rota', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('cadastrar pela tela cria a conta e abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherECadastrar(tester, 'bia@biblioteca.com', 'segredo456');

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Bia!'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('e-mail repetido: a tela mostra o erro e fica no cadastro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherECadastrar(tester, 'ana@biblioteca.com', 'segredo456');

    expect(find.text('Já existe uma conta com este e-mail'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.byType(InicioScreen), findsNothing);
  });

  testWidgets('o link Já tenho conta leva ao login', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('o guarda: sem sessão, a rota /inicio mostra o login', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    Navigator.of(tester.element(find.byType(LoginScreen))).pushNamed(AppRoutes.inicio);
    await tester.pumpAndSettle();

    expect(find.byType(InicioScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o menu mostra o nome sem receber nada pelo construtor', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherEEntrar(tester, 'segredo123');

    await abrirOMenu(tester);
    final menu = find.byType(Drawer);
    expect(find.descendant(of: menu, matching: find.text('Ana')), findsOneWidget);
    expect(find.descendant(of: menu, matching: find.text('ana@biblioteca.com')), findsOneWidget);

    await tester.tap(find.descendant(of: menu, matching: find.text('Perfil')));
    await tester.pumpAndSettle();

    expect(find.byType(PerfilScreen), findsOneWidget);
    await abrirOMenu(tester);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Ana')), findsOneWidget);
  });

  testWidgets('sair volta ao login, limpa a pilha e apaga a sessão', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(appDeMentira(sessao));
    await preencherEEntrar(tester, 'segredo123');
    await tester.tap(find.text('Ver os simulados'));
    await tester.pumpAndSettle();
    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(await tokenGuardado(), 'token-de-ana@biblioteca.com');

    await abrirOMenu(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SimuladosScreen), findsNothing);
    expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);
    expect(sessao.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  testWidgets('com a sessão restaurada, o app abre direto na tela inicial', (tester) async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    await sessao.restaurar();
    await tester.pumpWidget(appDeMentira(sessao));

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('o watch redesenha a tela quando o service avisa', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sessao,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final nome = context.watch<SessaoService>().usuario?.nome;
              return Text(nome ?? 'ninguém');
            },
          ),
        ),
      ),
    );
    expect(find.text('ninguém'), findsOneWidget);

    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
  });

  // Os quatro estados da tela de simulados: a lista, a vazia, o erro e o carregando.
  testWidgets('a tela de simulados mostra a lista: um ListTile por simulado', (tester) async {
    await abrirOsSimulados(tester, apiDeSimulados(200, doisSimulados));

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('ENEM 2025 - Dia 1'), findsOneWidget);
    expect(find.text('05/03/2026'), findsOneWidget);
  });

  testWidgets('sem simulado nenhum, a tela diz que a lista está vazia', (tester) async {
    await abrirOsSimulados(tester, apiDeSimulados(200, []));

    expect(find.text('Nenhum simulado ainda.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('com a API parada, o erro; o Tentar de novo pede outra vez', (tester) async {
    var noAr = false;
    final simulados = MockClient((pedido) async {
      if (!noAr) {
        throw http.ClientException('Failed to fetch');
      }
      return http.Response(jsonEncode(doisSimulados), 200);
    });
    await abrirOsSimulados(tester, simulados);

    expect(find.text('Não consegui carregar os simulados'), findsOneWidget);
    expect(find.text('Não consegui falar com a API. O uvicorn está rodando?'), findsOneWidget);

    noAr = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('ENEM 2025 - Dia 1'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('enquanto a resposta não chega, a tela mostra o carregando', (tester) async {
    final resposta = Completer<http.Response>();
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    await tester.pumpWidget(
      appDeMentira(sessao, simulados: MockClient((pedido) => resposta.future)),
    );
    await tester.tap(find.text('Ver os simulados'));
    // Sem pumpAndSettle: o círculo gira para sempre, e ele esperaria em vão.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete(http.Response(jsonEncode(doisSimulados), 200));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ENEM 2025 - Dia 1'), findsOneWidget);
  });

  testWidgets('tocar num simulado abre o detalhe, que busca o simulado na API pelo id', (tester) async {
    await abrirOsSimulados(tester, apiDeSimulados(200, doisSimulados));
    pedidos = 0;

    await tester.tap(find.text('Simulado de Matemática'));
    await tester.pumpAndSettle();

    expect(find.byType(SimuladoScreen), findsOneWidget);
    expect(find.text('05/03/2026'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
    expect(pedidos, 1);
  });

  testWidgets('o detalhe de um simulado que não existe mais mostra o erro da API', (tester) async {
    await abrirOsSimulados(tester, apiDeSimulados(200, doisSimulados));

    Navigator.of(tester.element(find.byType(SimuladosScreen))).pushNamed(AppRoutes.simulado, arguments: 99);
    await tester.pumpAndSettle();

    expect(find.text('Não consegui carregar o simulado'), findsOneWidget);
    expect(find.text('Simulado 99 nao esta no seu acervo'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('sem o id na rota (o F5 no detalhe), a tela mostra a lista', (tester) async {
    await abrirOsSimulados(tester, apiDeSimulados(200, doisSimulados));

    Navigator.of(tester.element(find.byType(SimuladosScreen))).pushNamed(AppRoutes.simulado);
    await tester.pumpAndSettle();

    expect(find.byType(SimuladoScreen), findsOneWidget);
    expect(find.text('ENEM 2025 - Dia 1'), findsOneWidget);
  });

  // Criar, editar e excluir pelo app: o formulário, as duas pontas da validação
  // e o diálogo de confirmação.
  testWidgets('o + abre o formulário vazio; salvar cria o simulado e a lista o mostra', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    expect(find.byType(ListTile), findsNWidgets(2));

    await abrirOFormularioEPreencher(tester, 'Simulado Novo', '15/12/2025');
    await tocarEmSalvar(tester);

    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Simulado Novo'), findsOneWidget);
    expect(find.text('15/12/2025'), findsOneWidget);
    // o dono nao vai no corpo: a API o tira do token (RN-05)
    expect(ultimoCorpo, {'identificacao': 'Simulado Novo', 'data_aplicacao': '2025-12-15'});
  });

  testWidgets('a ponta do app: campos vazios mostram as frases e nenhum pedido sai', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    pedidos = 0;

    await tocarEmSalvar(tester);

    expect(find.text('Informe a identificação'), findsOneWidget);
    expect(find.text('Informe uma data válida, como 09/11/2025'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
    expect(pedidos, 0);
  });

  testWidgets('uma data que não existe, como 31/02, é recusada no app, sem pedido', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    await abrirOFormularioEPreencher(tester, 'Simulado Novo', '31/02/2026');
    pedidos = 0;

    await tocarEmSalvar(tester);

    expect(find.text('Informe uma data válida, como 09/11/2025'), findsOneWidget);
    expect(pedidos, 0);
  });

  testWidgets('a ponta da API: a frase do 422 aparece na tela e o formulário fica aberto', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    await abrirOFormularioEPreencher(tester, 'AB', '15/12/2025');

    await tocarEmSalvar(tester);

    expect(find.text('identificacao: String should have at least 3 characters'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Salvar'), findsOneWidget);
  });

  testWidgets('Editar abre o mesmo formulário preenchido; salvar muda o simulado na lista', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    await abrirODetalhe(tester, 'ENEM 2025 - Dia 1');

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.byType(FormularioScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'ENEM 2025 - Dia 1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '09/11/2025'), findsOneWidget);

    await tester.enterText(campoIdentificacao, 'ENEM 2025 - Dia 2');
    await tocarEmSalvar(tester);

    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(find.text('ENEM 2025 - Dia 2'), findsOneWidget);
    expect(find.text('ENEM 2025 - Dia 1'), findsNothing);
    expect(ultimoCorpo, {'identificacao': 'ENEM 2025 - Dia 2', 'data_aplicacao': '2025-11-09'});
  });

  testWidgets('Excluir pergunta antes: Cancelar não muda nada, Excluir tira da lista', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());
    await abrirODetalhe(tester, 'Simulado de Matemática');

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Excluir Simulado de Matemática?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SimuladoScreen), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(excluirDoDialogo);
    await tester.pumpAndSettle();

    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(find.text('Simulado de Matemática'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(1));
  });

  testWidgets('sem quem o abriu (o F5 no formulário), a tela mostra a lista', (tester) async {
    await abrirOsSimulados(tester, acervoDeMentira());

    Navigator.of(tester.element(find.byType(SimuladosScreen))).pushNamedAndRemoveUntil(AppRoutes.formulario, (rota) => false);
    await tester.pumpAndSettle();

    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  // O service testado sozinho, sem tela nenhuma: é o que as camadas compram.
  test('o service recusa campos vazios sem nem chamar a API', () async {
    final sessao = sessaoDeMentira();
    pedidos = 0;

    await expectLater(sessao.entrar('', ''), throwsA(isA<ErroDeLogin>()));
    await expectLater(sessao.cadastrar('', '', ''), recusadoCom('Preencha o nome, o e-mail e a senha'));
    expect(pedidos, 0);
    expect(sessao.logado, isFalse);
  });

  test('entrar muda a sessão e avisa quem está de olho', () async {
    final sessao = sessaoDeMentira();
    var avisos = 0;
    sessao.addListener(() => avisos++);

    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    expect(sessao.token, 'token-de-ana@biblioteca.com');
    expect(sessao.usuario?.nome, 'Ana');
    expect(avisos, 1);
  });

  test('cadastrar cria a conta e já entra com ela, pelo mesmo caminho do login', () async {
    final sessao = sessaoDeMentira();

    await sessao.cadastrar('Bia', 'bia@biblioteca.com', 'segredo456');

    expect(sessao.logado, isTrue);
    expect(sessao.usuario?.nome, 'Bia');
    expect(sessao.token, 'token-de-bia@biblioteca.com');
  });

  test('o service traduz a recusa da API: e-mail repetido (409) e campo inválido (422)', () async {
    final sessao = sessaoDeMentira();

    await expectLater(
      sessao.cadastrar('Ana', 'ana@biblioteca.com', 'segredo123'),
      recusadoCom('Já existe uma conta com este e-mail'),
    );
    await expectLater(
      sessao.cadastrar('Bia', 'bia@biblioteca.com', '123'),
      recusadoCom('senha: String should have at least 6 characters'),
    );
    expect(sessao.logado, isFalse);
  });

  test('entrar guarda o token no aparelho', () async {
    final sessao = sessaoDeMentira();

    await sessao.entrar('ana@biblioteca.com', 'segredo123');

    expect(await tokenGuardado(), 'token-de-ana@biblioteca.com');
  });

  test('restaurar devolve a sessão a quem tem um token guardado', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    pedidos = 0;

    await sessao.restaurar();

    expect(sessao.logado, isTrue);
    expect(sessao.usuario?.nome, 'Ana');
    expect(pedidos, 1);
  });

  test('restaurar sem token guardado não pede nada à API', () async {
    final sessao = sessaoDeMentira();
    pedidos = 0;

    await sessao.restaurar();

    expect(sessao.logado, isFalse);
    expect(pedidos, 0);
  });

  test('restaurar apaga o token que a API não aceita mais', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-vencido'});

    await sessao.restaurar();

    expect(sessao.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  test('sair apaga o token guardado no aparelho', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    await sessao.restaurar();
    expect(sessao.logado, isTrue);

    await sessao.sair();

    expect(await tokenGuardado(), isNull);
  });

  test('o model monta o Simulado do JSON e escreve a data como dd/mm/aaaa', () {
    final simulado = Simulado.fromJson(doisSimulados.first);

    expect(simulado.id, 1);
    expect(simulado.identificacao, 'ENEM 2025 - Dia 1');
    expect(simulado.dataAplicacao, DateTime(2025, 11, 9));
    expect(simulado.dataFormatada, '09/11/2025');
    expect(simulado.ativo, isTrue);
  });

  test('o repositório manda o token no cabeçalho e devolve objetos Simulado', () async {
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(doisSimulados), 200);
    });

    final simulados = await SimuladoRepository(cliente: cliente).listar('tk-123');

    expect(cabecalho, 'Bearer tk-123');
    expect(simulados, hasLength(2));
    expect(simulados.first, isA<Simulado>());
    expect(simulados.first.identificacao, 'ENEM 2025 - Dia 1');
  });

  test('o repositório busca um simulado só pelo id, com o token: GET /simulados/2', () async {
    String? caminho;
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      caminho = pedido.url.path;
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(doisSimulados.last), 200);
    });

    final simulado = await SimuladoRepository(cliente: cliente).buscar('tk-123', 2);

    expect(caminho, '/simulados/2');
    expect(cabecalho, 'Bearer tk-123');
    expect(simulado.identificacao, 'Simulado de Matemática');
  });

  test('o service dos simulados traduz a recusa: a frase da API vai para a tela', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final recusa = apiDeSimulados(401, {'detail': 'Token invalido ou vencido'});
    final servico = SimuladoService(SimuladoRepository(cliente: recusa), sessao);

    await expectLater(
      servico.listar(),
      throwsA(isA<ErroDeSimulados>().having((e) => e.mensagem, 'mensagem', 'Token invalido ou vencido')),
    );
  });

  test('o service dos simulados troca a falha de rede por uma frase', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final fora = MockClient((pedido) async => throw http.ClientException('Failed to fetch'));
    final servico = SimuladoService(SimuladoRepository(cliente: fora), sessao);

    await expectLater(
      servico.buscar(1),
      throwsA(isA<ErroDeSimulados>().having(
        (e) => e.mensagem,
        'mensagem',
        'Não consegui falar com a API. O uvicorn está rodando?',
      )),
    );
  });

  test('o repositório cria com POST: JSON no corpo, o token no cabeçalho e sem o dono', () async {
    late http.Request enviado;
    final cliente = MockClient((pedido) async {
      enviado = pedido;
      return http.Response(jsonEncode(doisSimulados.first), 201);
    });

    final simulado = await SimuladoRepository(cliente: cliente).criar('tk-123', 'ENEM 2025 - Dia 1', DateTime(2025, 11, 9));

    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/simulados/');
    expect(enviado.headers['Authorization'], 'Bearer tk-123');
    expect(enviado.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(enviado.body), {'identificacao': 'ENEM 2025 - Dia 1', 'data_aplicacao': '2025-11-09'});
    expect(simulado.id, 1);
  });

  test('o repositório edita com PATCH em /simulados/2 e exclui com DELETE', () async {
    final vistos = <String>[];
    final cliente = MockClient((pedido) async {
      vistos.add('${pedido.method} ${pedido.url.path}');
      if (pedido.method == 'DELETE') {
        return http.Response('', 204);
      }
      return http.Response(jsonEncode(doisSimulados.last), 200);
    });
    final repositorio = SimuladoRepository(cliente: cliente);

    await repositorio.atualizar('tk-123', 2, 'Simulado de Matemática', DateTime(2026, 3, 5));
    await repositorio.excluir('tk-123', 2);

    expect(vistos, ['PATCH /simulados/2', 'DELETE /simulados/2']);
  });

  test('o repositório transforma a recusa da API (404 ao excluir) em RecusaDaApi', () async {
    final cliente = MockClient((pedido) async => http.Response('{"detail": "Simulado 9 nao esta no seu acervo"}', 404));

    await expectLater(
      SimuladoRepository(cliente: cliente).excluir('tk-123', 9),
      throwsA(isA<RecusaDaApi>().having((e) => e.status, 'status', 404)),
    );
  });

  test('o service traduz o 422 do criar: a frase da API vai para a tela', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final servico = SimuladoService(SimuladoRepository(cliente: acervoDeMentira()), sessao);

    await expectLater(
      servico.criar('AB', DateTime(2025, 11, 9)),
      throwsA(isA<ErroDeSimulados>().having(
        (e) => e.mensagem,
        'mensagem',
        'identificacao: String should have at least 3 characters',
      )),
    );
  });

  test('lerData aceita dd/mm/aaaa de verdade e recusa o resto', () {
    expect(lerData('09/11/2025'), DateTime(2025, 11, 9));
    expect(lerData('9/1/2026'), DateTime(2026, 1, 9)); // dia e mês podem ter 1 dígito; o ano, não
    expect(lerData('29/02/2024'), DateTime(2024, 2, 29)); // ano bissexto
    for (final invalida in ['', '9/11', '31/02/2026', '29/02/2025', 'aa/bb/cccc', '09/11/25', '09-11-2025', '32/01/2026', '10/13/2026']) {
      expect(lerData(invalida), isNull, reason: 'devia recusar "$invalida"');
    }
  });

  test('dataParaApi escreve aaaa-mm-dd e formatarData escreve dd/mm/aaaa', () {
    expect(dataParaApi(DateTime(2025, 3, 5)), '2025-03-05');
    expect(formatarData(DateTime(2025, 3, 5)), '05/03/2025');
  });

  test('fraseDaApi tira o "Value error, " que o Pydantic põe na frente', () {
    const corpo = '{"detail": [{"loc": ["body", "ano"], "msg": "Value error, o ano precisa estar entre 1450 e 2100"}]}';

    expect(fraseDaApi(corpo), 'ano: o ano precisa estar entre 1450 e 2100');
  });
}
