import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aluno.dart';
import '../models/catalogo.dart';
import '../models/questao.dart';
import '../routes.dart';
import '../services/correcao_service.dart';
import '../services/questao_service.dart';
import '../services/traducao.dart';
import '../widgets/estados_da_tela.dart';

typedef GabaritoDoAluno = ({List<Questao> questoes, Map<int, String> marcadas});

// O gabarito de um aluno em um simulado: uma linha por questão, com as letras A
// a E para marcar o que o aluno respondeu. A questão sem letra fica em branco e
// conta como erro. Salvar manda tudo de uma vez (PUT) e já abre a correção.
class RespostasScreen extends StatefulWidget {
  const RespostasScreen({super.key, required this.simuladoId, required this.aluno});

  final int simuladoId;
  final Aluno aluno;

  @override
  State<RespostasScreen> createState() => _RespostasScreenState();
}

class _RespostasScreenState extends State<RespostasScreen> {
  late Future<GabaritoDoAluno> pedido;

  // O que está marcado na tela: começa com o que o aluno já tinha na API, e só
  // vai para a API no Salvar. Nasce na primeira vez que os dados chegam.
  Map<int, String>? escolhas;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    pedido = carregar();
  }

  Future<GabaritoDoAluno> carregar() async {
    // Os services saem do context ANTES do primeiro await: depois dele, a tela
    // pode já ter fechado.
    final questaoService = context.read<QuestaoService>();
    final correcaoService = context.read<CorrecaoService>();
    final questoes = await questaoService.listar(widget.simuladoId);
    final marcadas = await correcaoService.respostas(widget.simuladoId, widget.aluno.id);
    return (questoes: questoes, marcadas: marcadas);
  }

  void pedirDeNovo() {
    setState(() {
      escolhas = null;
      pedido = carregar();
    });
  }

  Future<void> salvarECorrigir() async {
    if (escolhas == null || escolhas!.isEmpty) {
      setState(() {
        erro = 'Marque ao menos uma resposta';
      });
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await context.read<CorrecaoService>().lancar(widget.simuladoId, widget.aluno.id, escolhas!);
    } on ErroDeApi catch (e) {
      setState(() {
        salvando = false;
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      salvando = false;
    });
    await Navigator.pushNamed(
      context,
      AppRoutes.resultado,
      arguments: (simuladoId: widget.simuladoId, aluno: widget.aluno),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Respostas de ${widget.aluno.nome}')),
      body: EstadosDaTela<GabaritoDoAluno>(
        pedido: pedido,
        tituloDoErro: 'Não consegui carregar as questões',
        pedirDeNovo: pedirDeNovo,
        estaVazio: (dados) => dados.questoes.isEmpty,
        mensagemVazia: 'Este simulado ainda não tem questões. Cadastre as questões primeiro.',
        construir: (context, dados) {
          escolhas ??= {...dados.marcadas};
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final questao in dados.questoes)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Questão ${questao.numero} · ${questao.componente}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final letra in alternativas)
                                    ChoiceChip(
                                      key: ValueKey('q${questao.numero}-$letra'),
                                      label: Text(letra),
                                      selected: escolhas![questao.numero] == letra,
                                      // Tocar na letra marcada desmarca: volta a ficar em branco.
                                      onSelected: (marcou) {
                                        setState(() {
                                          if (marcou) {
                                            escolhas![questao.numero] = letra;
                                          } else {
                                            escolhas!.remove(questao.numero);
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (erro != null) ...[
                      Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: salvando ? null : salvarECorrigir,
                      icon: const Icon(Icons.fact_check),
                      label: Text(salvando ? 'Salvando...' : 'Salvar e corrigir'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
