import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:frontend/main.dart';
import 'package:frontend/models/aluno.dart';
import 'package:frontend/repositories/correcao_repository.dart';
import 'package:frontend/repositories/questao_repository.dart';
import 'package:frontend/repositories/simulado_repository.dart';
import 'package:frontend/repositories/turma_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/services/correcao_service.dart';
import 'package:frontend/services/questao_service.dart';
import 'package:frontend/services/sessao_service.dart';
import 'package:frontend/services/simulado_service.dart';
import 'package:frontend/services/traducao.dart';
import 'package:frontend/services/turma_service.dart';
import 'package:frontend/telas/aluno_formulario_screen.dart';
import 'package:frontend/telas/correcao_screen.dart';
import 'package:frontend/telas/questao_formulario_screen.dart';
import 'package:frontend/telas/questoes_screen.dart';
import 'package:frontend/telas/respostas_screen.dart';
import 'package:frontend/telas/resultado_screen.dart';
import 'package:frontend/telas/simulados_screen.dart';
import 'package:frontend/telas/turma_screen.dart';
import 'package:frontend/telas/turmas_screen.dart';

import 'telas_test.dart' show doisSimulados, sessaoDeMentira;

// Uma API de mentira com TODAS as rotas do sistema e um banco de mentira: as
// listas MUDAM quando o app cria, edita, exclui ou lança respostas, e a correção
// é calculada como a de verdade (acertos ÷ total × 10). Cada teste monta a sua.
class ApiDeMentira {
  ApiDeMentira({bool comQuestoes = true, bool comTurma = true, Map<int, String>? marcadasDoBruno}) {
    if (comQuestoes) {
      // O gabarito do simulado 1: 1=A e 2=B de Matemática, 3=C de Português.
      questoes.addAll([
        _questao(1, 'A', 'MATEMÁTICA'),
        _questao(2, 'B', 'MATEMÁTICA'),
        _questao(3, 'C', 'PORTUGUÊS'),
      ]);
    }
    if (comTurma) {
      turmas.add({'id': 1, 'nome': '3o A', 'ativo': true});
      alunos.addAll([
        {'id': 1, 'nome': 'Bruno', 'turma_id': 1, 'ativo': true},
        {'id': 2, 'nome': 'Carla', 'turma_id': 1, 'ativo': true},
      ]);
    }
    if (marcadasDoBruno != null) {
      respostas['1-1'] = {...marcadasDoBruno};
    }
  }

  final questoes = <Map<String, dynamic>>[];
  final turmas = <Map<String, dynamic>>[];
  final alunos = <Map<String, dynamic>>[];
  final respostas = <String, Map<int, String>>{}; // 'simulado-aluno' -> {questão: letra}
  var proximaTurma = 2;
  var proximoAluno = 3;
  var proximaQuestao = 4;
  var lancamentos = 0; // quantos PUT de respostas chegaram
  Map<String, dynamic>? ultimoCorpo;

  static Map<String, dynamic> _questao(int numero, String certa, String componente) => {
        'id': numero,
        'numero_questao': numero,
        'alternativa_correta': certa,
        'componente_curricular': componente,
        'conteudo': null,
        'simulado_id': 1,
      };

  http.Response _json(Object corpo, [int status = 200]) => http.Response(jsonEncode(corpo), status);

  http.Response _recusa(String campo, String mensagem) => _json({
        'detail': [
          {
            'loc': ['body', campo],
            'msg': mensagem,
          },
        ],
      }, 422);

  http.Client get cliente => MockClient((pedido) async {
        if (pedido.headers['Authorization'] == null) {
          return http.Response('{"detail": "Not authenticated"}', 401);
        }
        final partes = pedido.url.pathSegments.where((p) => p.isNotEmpty).toList();
        final metodo = pedido.method;
        final corpo = pedido.body.isEmpty ? null : jsonDecode(pedido.body) as Map<String, dynamic>;
        if (corpo != null) ultimoCorpo = corpo;

        // /simulados e /simulados/{id}
        if (partes.first == 'simulados' && (partes.length == 1 || partes.length == 2)) {
          if (partes.length == 1) return _json(doisSimulados);
          final achado = doisSimulados.where((s) => '${s['id']}' == partes[1]);
          return achado.isEmpty
              ? http.Response('{"detail": "Simulado ${partes[1]} nao esta no seu acervo"}', 404)
              : _json(achado.first);
        }
        // /simulados/{id}/questoes[/{qid}]
        if (partes.first == 'simulados' && partes.length >= 3 && partes[2] == 'questoes') {
          if (partes.length == 3 && metodo == 'GET') return _json(questoes);
          if (partes.length == 3 && metodo == 'POST') {
            final nova = _questao(proximaQuestao, corpo!['alternativa_correta'], corpo['componente_curricular']);
            nova['id'] = proximaQuestao;
            nova['numero_questao'] = proximaQuestao++;
            nova['conteudo'] = corpo['conteudo'];
            questoes.add(nova);
            return _json(nova, 201);
          }
          final i = questoes.indexWhere((q) => '${q['id']}' == partes[3]);
          if (i < 0) return http.Response('{"detail": "Questao nao encontrada"}', 404);
          questoes[i] = {...questoes[i], ...corpo!};
          return _json(questoes[i]);
        }
        // /simulados/{sid}/alunos/{aid}/respostas|resultado
        if (partes.first == 'simulados' && partes.length == 5 && partes[2] == 'alunos') {
          final chave = '${partes[1]}-${partes[3]}';
          final marcadas = respostas[chave] ?? {};
          if (partes[4] == 'respostas' && metodo == 'GET') {
            return _json([
              for (final e in marcadas.entries) {'numero_questao': e.key, 'alternativa_escolhida': e.value},
            ]);
          }
          if (partes[4] == 'respostas' && metodo == 'PUT') {
            lancamentos++;
            final itens = corpo!['respostas'] as List;
            final numeros = questoes.map((q) => q['numero_questao']).toSet();
            for (final item in itens) {
              if (!numeros.contains(item['numero_questao'])) {
                return http.Response('{"detail": "O simulado 1 nao tem a questao ${item['numero_questao']}"}', 422);
              }
            }
            respostas[chave] = {for (final i in itens) i['numero_questao'] as int: i['alternativa'] as String};
            return _json([
              for (final e in respostas[chave]!.entries) {'numero_questao': e.key, 'alternativa_escolhida': e.value},
            ]);
          }
          if (partes[4] == 'resultado') {
            var acertos = 0;
            final porComponente = <String, List<int>>{}; // componente -> [acertos, total]
            for (final q in questoes) {
              final contadores = porComponente.putIfAbsent(q['componente_curricular'], () => [0, 0]);
              contadores[1]++;
              if (marcadas[q['numero_questao']] == q['alternativa_correta']) {
                contadores[0]++;
                acertos++;
              }
            }
            final total = questoes.length;
            return _json({
              'aluno_id': int.parse(partes[3]),
              'simulado_id': int.parse(partes[1]),
              'total_questoes': total,
              'total_acertos': acertos,
              'nota': total == 0 ? 0.0 : double.parse((acertos / total * 10).toStringAsFixed(2)),
              'acertos_por_componente': [
                for (final e in porComponente.entries) {'componente': e.key, 'acertos': e.value[0], 'total': e.value[1]},
              ],
            });
          }
        }
        // /turmas e /turmas/{id}
        if (partes.first == 'turmas' && partes.length <= 2) {
          if (partes.length == 1 && metodo == 'GET') return _json(turmas);
          if (partes.length == 1 && metodo == 'POST') {
            if ((corpo!['nome'] as String).length < 2) {
              return _recusa('nome', 'Value error, O nome precisa ter pelo menos 2 caracteres');
            }
            final nova = {'id': proximaTurma++, 'nome': corpo['nome'], 'ativo': true};
            turmas.add(nova);
            return _json(nova, 201);
          }
          final i = turmas.indexWhere((t) => '${t['id']}' == partes[1]);
          if (i < 0) return http.Response('{"detail": "Turma ${partes[1]} nao esta no seu acervo"}', 404);
          if (metodo == 'PATCH') {
            turmas[i] = {...turmas[i], ...corpo!};
            return _json(turmas[i]);
          }
          if (metodo == 'DELETE') {
            alunos.removeWhere((a) => '${a['turma_id']}' == partes[1]);
            turmas.removeAt(i);
            return http.Response('', 204);
          }
          return _json(turmas[i]);
        }
        // /turmas/{tid}/alunos[/{aid}]
        if (partes.first == 'turmas' && partes.length >= 3 && partes[2] == 'alunos') {
          if (partes.length == 3 && metodo == 'GET') {
            return _json(alunos.where((a) => '${a['turma_id']}' == partes[1]).toList());
          }
          if (partes.length == 3 && metodo == 'POST') {
            final novo = {'id': proximoAluno++, 'nome': corpo!['nome'], 'turma_id': int.parse(partes[1]), 'ativo': true};
            alunos.add(novo);
            return _json(novo, 201);
          }
          final i = alunos.indexWhere((a) => '${a['id']}' == partes[3]);
          if (i < 0) return http.Response('{"detail": "Aluno ${partes[3]} nao encontrado"}', 404);
          if (metodo == 'PATCH') {
            alunos[i] = {...alunos[i], ...corpo!};
            return _json(alunos[i]);
          }
          alunos.removeAt(i);
          return http.Response('', 204);
        }
        return http.Response('{"detail": "rota desconhecida"}', 404);
      });
}

// O app de verdade, com os cinco services de mentira no topo, como o main.dart faz.
Widget appCompleto(SessaoService sessao, ApiDeMentira api) {
  final cliente = api.cliente;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sessao),
      Provider.value(value: SimuladoService(SimuladoRepository(cliente: cliente), sessao)),
      Provider.value(value: QuestaoService(QuestaoRepository(cliente: cliente), sessao)),
      Provider.value(value: TurmaService(TurmaRepository(cliente: cliente), sessao)),
      Provider.value(value: CorrecaoService(CorrecaoRepository(cliente: cliente), sessao)),
    ],
    child: const GabGradingApp(),
  );
}

// A Ana entra e chega à tela inicial.
Future<void> entrar(WidgetTester tester, ApiDeMentira api) async {
  final sessao = sessaoDeMentira();
  await sessao.entrar('ana@biblioteca.com', 'segredo123');
  await tester.pumpWidget(appCompleto(sessao, api));
}

// ... e abre o detalhe do primeiro simulado.
Future<void> abrirODetalheDoSimulado(WidgetTester tester, ApiDeMentira api) async {
  await entrar(tester, api);
  await tester.tap(find.text('Ver os simulados'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ENEM 2025 - Dia 1'));
  await tester.pumpAndSettle();
}

// ... e abre a lista de turmas pelo menu.
Future<void> abrirAsTurmas(WidgetTester tester, ApiDeMentira api) async {
  await entrar(tester, api);
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Turmas')));
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

Future<void> tocarNoBotao(WidgetTester tester, String texto) async {
  await tester.tap(find.widgetWithText(ElevatedButton, texto));
  await tester.pumpAndSettle();
}

// Escolhe uma opção de uma lista suspensa: toca no campo e depois na opção.
Future<void> escolher(WidgetTester tester, String campo, String opcao) async {
  await tester.tap(find.text(campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

Future<void> marcar(WidgetTester tester, int questao, String letra) async {
  await tester.tap(find.byKey(ValueKey('q$questao-$letra')));
  await tester.pumpAndSettle();
}

// O botão Excluir DENTRO do diálogo (a tela também pode ter um Excluir).
Finder get excluirDoDialogo => find.descendant(of: find.byType(AlertDialog), matching: find.text('Excluir'));

void main() {
  // --- As questões e o gabarito do simulado
  testWidgets('o detalhe do simulado abre as questões, cada uma com o gabarito', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira());

    await tocar(tester, 'Questões e gabarito');

    expect(find.byType(QuestoesScreen), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Gabarito: A'), findsOneWidget);
    expect(find.text('Gabarito: C'), findsOneWidget);
    expect(find.text('PORTUGUÊS'), findsOneWidget);
  });

  testWidgets('sem questões, a tela diz que a lista está vazia', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira(comQuestoes: false));

    await tocar(tester, 'Questões e gabarito');

    expect(find.text('Nenhuma questão ainda. Toque no + para cadastrar.'), findsOneWidget);
  });

  testWidgets('o + cadastra uma questão: a API numera, e a lista mostra a quarta', (tester) async {
    final api = ApiDeMentira();
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Questões e gabarito');

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await escolher(tester, 'Componente curricular', 'MATEMÁTICA');
    await escolher(tester, 'Alternativa certa', 'E');
    await tocarNoBotao(tester, 'Salvar');

    expect(find.byType(QuestoesScreen), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.text('Gabarito: E'), findsOneWidget);
    // o número não vai no corpo (RN-12), nem o conteúdo em branco como texto
    expect(api.ultimoCorpo, {'alternativa_correta': 'E', 'componente_curricular': 'MATEMÁTICA', 'conteudo': null});
  });

  testWidgets('a questão sem as duas escolhas é recusada no app, com as frases', (tester) async {
    final api = ApiDeMentira();
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Questões e gabarito');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    api.ultimoCorpo = null;

    await tocarNoBotao(tester, 'Salvar');

    expect(find.text('Escolha o componente curricular'), findsOneWidget);
    expect(find.text('Escolha a alternativa certa'), findsOneWidget);
    expect(find.byType(QuestaoFormularioScreen), findsOneWidget);
    expect(api.ultimoCorpo, isNull);
  });

  testWidgets('tocar numa questão abre a edição preenchida; salvar muda o gabarito', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira());
    await tocar(tester, 'Questões e gabarito');

    await tocar(tester, 'Gabarito: A');
    expect(find.text('Editar questão 1'), findsOneWidget);
    await escolher(tester, 'Alternativa certa', 'D');
    await tocarNoBotao(tester, 'Salvar');

    expect(find.text('Gabarito: D'), findsOneWidget);
    expect(find.text('Gabarito: A'), findsNothing);
  });

  // --- Turmas e alunos
  testWidgets('o menu leva às turmas, que mostram a lista da API', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira());

    expect(find.byType(TurmasScreen), findsOneWidget);
    expect(find.text('3o A'), findsOneWidget);
  });

  testWidgets('sem turmas, a lista diz que está vazia', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira(comTurma: false));

    expect(find.text('Nenhuma turma ainda. Toque no + para cadastrar.'), findsOneWidget);
  });

  testWidgets('o + cadastra a turma; um nome vazio é recusado no app; o de 1 letra, pela API', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tocarNoBotao(tester, 'Salvar');
    expect(find.text('Informe o nome da turma'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'A');
    await tocarNoBotao(tester, 'Salvar');
    expect(find.text('nome: O nome precisa ter pelo menos 2 caracteres'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '3o B');
    await tocarNoBotao(tester, 'Salvar');
    expect(find.byType(TurmasScreen), findsOneWidget);
    expect(find.text('3o B'), findsOneWidget);
  });

  testWidgets('o detalhe da turma mostra os alunos; Adicionar aluno cadastra e recarrega', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira());
    await tocar(tester, '3o A');

    expect(find.byType(TurmaScreen), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);

    await tocar(tester, 'Adicionar aluno');
    await tester.enterText(find.byType(TextFormField), 'Diego');
    await tocarNoBotao(tester, 'Salvar');

    expect(find.byType(TurmaScreen), findsOneWidget);
    expect(find.text('Diego'), findsOneWidget);
  });

  testWidgets('tocar num aluno edita o nome; Excluir aluno pergunta antes', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira());
    await tocar(tester, '3o A');

    await tocar(tester, 'Bruno');
    expect(find.byType(AlunoFormularioScreen), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Bruno Silva');
    await tocarNoBotao(tester, 'Salvar');
    expect(find.text('Bruno Silva'), findsOneWidget);

    await tocar(tester, 'Bruno Silva');
    await tocar(tester, 'Excluir aluno');
    await tocar(tester, 'Cancelar');
    expect(find.byType(AlunoFormularioScreen), findsOneWidget);

    await tocar(tester, 'Excluir aluno');
    await tester.tap(excluirDoDialogo);
    await tester.pumpAndSettle();
    expect(find.byType(TurmaScreen), findsOneWidget);
    expect(find.text('Bruno Silva'), findsNothing);
    expect(find.text('Carla'), findsOneWidget);
  });

  testWidgets('Editar a turma muda o nome na lista; Excluir pergunta e a tira da lista', (tester) async {
    await abrirAsTurmas(tester, ApiDeMentira());
    await tocar(tester, '3o A');

    await tocar(tester, 'Editar');
    await tester.enterText(find.byType(TextFormField), '3o A (manhã)');
    await tocarNoBotao(tester, 'Salvar');
    expect(find.byType(TurmasScreen), findsOneWidget);
    expect(find.text('3o A (manhã)'), findsOneWidget);

    await tocar(tester, '3o A (manhã)');
    await tocar(tester, 'Excluir');
    expect(find.text('Excluir 3o A (manhã)?'), findsOneWidget);
    await tester.tap(excluirDoDialogo);
    await tester.pumpAndSettle();
    expect(find.byType(TurmasScreen), findsOneWidget);
    expect(find.text('3o A (manhã)'), findsNothing);
  });

  // --- Corrigir: lançar as respostas e ver o resultado
  testWidgets('Corrigir alunos lista as turmas com os alunos de cada uma', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira());

    await tocar(tester, 'Corrigir alunos');

    expect(find.byType(CorrecaoScreen), findsOneWidget);
    expect(find.text('3o A'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);
  });

  testWidgets('sem alunos cadastrados, a correção manda cadastrar primeiro', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira(comTurma: false));

    await tocar(tester, 'Corrigir alunos');

    expect(find.text('Cadastre uma turma com alunos (menu Turmas) antes de corrigir.'), findsOneWidget);
  });

  testWidgets('lançar as respostas do Bruno e corrigir: nota, acertos e acertos por componente', (tester) async {
    final api = ApiDeMentira();
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Corrigir alunos');
    await tocar(tester, 'Bruno');
    expect(find.byType(RespostasScreen), findsOneWidget);
    expect(find.text('Questão 1 · MATEMÁTICA'), findsOneWidget);
    expect(find.text('Questão 3 · PORTUGUÊS'), findsOneWidget);

    await marcar(tester, 1, 'A'); // certa
    await marcar(tester, 2, 'E'); // errada
    await marcar(tester, 3, 'C'); // certa
    await tocarNoBotao(tester, 'Salvar e corrigir');

    expect(api.lancamentos, 1);
    expect(api.respostas['1-1'], {1: 'A', 2: 'E', 3: 'C'});
    expect(find.byType(ResultadoScreen), findsOneWidget);
    expect(find.text('Resultado de Bruno'), findsOneWidget);
    expect(find.text('6,67'), findsOneWidget);
    expect(find.text('2 de 3 acertos'), findsOneWidget);
    expect(find.text('MATEMÁTICA'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('PORTUGUÊS'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('as respostas já lançadas voltam marcadas, e dá para trocar uma', (tester) async {
    final api = ApiDeMentira(marcadasDoBruno: {1: 'A', 2: 'B', 3: 'E'});
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Corrigir alunos');
    await tocar(tester, 'Bruno');

    bool marcada(int q, String letra) => tester.widget<ChoiceChip>(find.byKey(ValueKey('q$q-$letra'))).selected;
    expect(marcada(1, 'A'), isTrue);
    expect(marcada(2, 'B'), isTrue);
    expect(marcada(3, 'E'), isTrue);
    expect(marcada(3, 'C'), isFalse);

    await marcar(tester, 3, 'C'); // troca a 3: de E para C
    await tocarNoBotao(tester, 'Salvar e corrigir');

    expect(find.text('10,00'), findsOneWidget);
    expect(find.text('3 de 3 acertos'), findsOneWidget);
  });

  testWidgets('tocar na letra marcada desmarca: a questão fica em branco e conta como erro', (tester) async {
    final api = ApiDeMentira(marcadasDoBruno: {1: 'A', 2: 'B', 3: 'C'});
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Corrigir alunos');
    await tocar(tester, 'Bruno');

    await marcar(tester, 2, 'B'); // desmarca
    await tocarNoBotao(tester, 'Salvar e corrigir');

    expect(api.respostas['1-1'], {1: 'A', 3: 'C'});
    expect(find.text('6,67'), findsOneWidget);
  });

  testWidgets('salvar sem marcar nada é recusado no app, sem pedido', (tester) async {
    final api = ApiDeMentira();
    await abrirODetalheDoSimulado(tester, api);
    await tocar(tester, 'Corrigir alunos');
    await tocar(tester, 'Bruno');

    await tocarNoBotao(tester, 'Salvar e corrigir');

    expect(find.text('Marque ao menos uma resposta'), findsOneWidget);
    expect(api.lancamentos, 0);
    expect(find.byType(RespostasScreen), findsOneWidget);
  });

  testWidgets('simulado sem questões: a tela de respostas manda cadastrá-las', (tester) async {
    await abrirODetalheDoSimulado(tester, ApiDeMentira(comQuestoes: false));
    await tocar(tester, 'Corrigir alunos');

    await tocar(tester, 'Bruno');

    expect(find.text('Este simulado ainda não tem questões. Cadastre as questões primeiro.'), findsOneWidget);
  });

  testWidgets('o F5 nas telas de detalhe (sem os arguments) mostra a lista, e não quebra', (tester) async {
    await entrar(tester, ApiDeMentira());
    final navegador = Navigator.of(tester.element(find.byType(Scaffold).first));

    navegador.pushNamedAndRemoveUntil(AppRoutes.turma, (rota) => false);
    await tester.pumpAndSettle();
    expect(find.byType(TurmasScreen), findsOneWidget);
    expect(find.byType(TurmaScreen), findsNothing);

    Navigator.of(tester.element(find.byType(Scaffold).first)).pushNamedAndRemoveUntil(AppRoutes.respostas, (rota) => false);
    await tester.pumpAndSettle();
    expect(find.byType(SimuladosScreen), findsOneWidget);
    expect(find.byType(RespostasScreen), findsNothing);
  });

  // --- As camadas, sem tela nenhuma
  test('o repositório lança as respostas com PUT: o gabarito inteiro, letra por número', () async {
    late http.Request enviado;
    final cliente = MockClient((pedido) async {
      enviado = pedido;
      return http.Response('[]', 200);
    });

    await CorrecaoRepository(cliente: cliente).lancar('tk-123', 1, 7, {1: 'A', 3: 'C'});

    expect(enviado.method, 'PUT');
    expect(enviado.url.path, '/simulados/1/alunos/7/respostas');
    expect(enviado.headers['Authorization'], 'Bearer tk-123');
    expect(jsonDecode(enviado.body), {
      'respostas': [
        {'numero_questao': 1, 'alternativa': 'A'},
        {'numero_questao': 3, 'alternativa': 'C'},
      ],
    });
  });

  test('o repositório lê as respostas marcadas e o resultado, mesmo com a nota inteira', () async {
    final cliente = MockClient((pedido) async {
      if (pedido.url.path.endsWith('/respostas')) {
        return http.Response(jsonEncode([{'numero_questao': 2, 'alternativa_escolhida': 'B'}]), 200);
      }
      return http.Response(
        jsonEncode({
          'aluno_id': 7,
          'simulado_id': 1,
          'total_questoes': 2,
          'total_acertos': 2,
          'nota': 10, // a API pode mandar 10, e não 10.0
          'acertos_por_componente': [{'componente': 'MATEMÁTICA', 'acertos': 2, 'total': 2}],
        }),
        200,
      );
    });
    final repositorio = CorrecaoRepository(cliente: cliente);

    expect(await repositorio.respostas('tk', 1, 7), {2: 'B'});
    final resultado = await repositorio.resultado('tk', 1, 7);
    expect(resultado.nota, 10.0);
    expect(resultado.porComponente.single.componente, 'MATEMÁTICA');
  });

  test('o service das questões manda o conteúdo em branco como null', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final api = ApiDeMentira(comQuestoes: false);
    final servico = QuestaoService(QuestaoRepository(cliente: api.cliente), sessao);

    await servico.criar(1, 'A', 'MATEMÁTICA', '   ');
    expect(api.ultimoCorpo!['conteudo'], isNull);

    await servico.criar(1, 'B', 'PORTUGUÊS', ' Verbos ');
    expect(api.ultimoCorpo!['conteudo'], 'Verbos');
  });

  test('o repositório da turma cria o aluno em /turmas/{id}/alunos/', () async {
    late http.Request enviado;
    final cliente = MockClient((pedido) async {
      enviado = pedido;
      return http.Response(jsonEncode({'id': 9, 'nome': 'Diego', 'turma_id': 4, 'ativo': true}), 201);
    });

    final Aluno aluno = await TurmaRepository(cliente: cliente).criarAluno('tk-123', 4, 'Diego');

    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/turmas/4/alunos/');
    expect(jsonDecode(enviado.body), {'nome': 'Diego'});
    expect(aluno.turmaId, 4);
  });

  test('traduzir: a recusa da API vira a frase dela; a falha de rede, a frase do uvicorn', () async {
    final recusada = MockClient((pedido) async => http.Response('{"detail": "Turma 9 nao esta no seu acervo"}', 404));
    final caida = MockClient((pedido) async => throw http.ClientException('Failed to fetch'));

    await expectLater(
      traduzir(() => TurmaRepository(cliente: recusada).buscar('tk', 9)),
      throwsA(isA<ErroDeApi>().having((e) => e.mensagem, 'mensagem', 'Turma 9 nao esta no seu acervo')),
    );
    await expectLater(
      traduzir(() => TurmaRepository(cliente: caida).buscar('tk', 9)),
      throwsA(isA<ErroDeApi>().having((e) => e.mensagem, 'mensagem', semApi)),
    );
  });

  test('o service da turma junta cada turma com os alunos dela', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final servico = TurmaService(TurmaRepository(cliente: ApiDeMentira().cliente), sessao);

    final turmas = await servico.turmasComAlunos();

    expect(turmas, hasLength(1));
    expect(turmas.single.turma.nome, '3o A');
    expect(turmas.single.alunos.map((a) => a.nome), ['Bruno', 'Carla']);
  });
}
