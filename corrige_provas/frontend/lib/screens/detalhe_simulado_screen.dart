import 'package:flutter/material.dart';

import '../models/simulado.dart';
import '../state/app_state.dart';
import '../widgets/confirmacao_dialog.dart';
import '../widgets/status_badge.dart';
import 'formulario_simulado_screen.dart';

class DetalheSimuladoScreen extends StatefulWidget {
  final AppState appState;
  final String simuladoId;

  const DetalheSimuladoScreen({
    super.key,
    required this.appState,
    required this.simuladoId,
  });

  @override
  State<DetalheSimuladoScreen> createState() =>
      _DetalheSimuladoScreenState();
}

class _DetalheSimuladoScreenState
    extends State<DetalheSimuladoScreen> {
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Simulado? get _simulado {
    for (final item in widget.appState.simulados) {
      if (item.id == widget.simuladoId) return item;
    }
    return null;
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alternarStatus(Simulado simulado) async {
    final bloqueando = simulado.status == StatusResultados.liberados;

    if (bloqueando) {
      final confirmou = await confirmarBloqueio(context);
      if (!confirmou || !mounted) return;
    }

    widget.appState.alternarStatus(simulado.id);

    _mensagem(
      bloqueando
          ? 'Resultados bloqueados.'
          : 'Resultados liberados para os alunos.',
    );
  }

  Future<void> _excluir(Simulado simulado) async {
    final confirmou = await confirmarExclusao(context);

    if (!confirmou || !mounted) return;

    widget.appState.excluir(simulado.id);
    Navigator.pop(context, 'Simulado excluído com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final simulado = _simulado;

        if (simulado == null) {
          return const Scaffold(
            body: Center(child: Text('Simulado não encontrado.')),
          );
        }

        final resultadosLiberados =
            simulado.status == StatusResultados.liberados;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes do simulado'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                simulado.titulo,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              StatusBadge(status: simulado.status),
                              const SizedBox(height: 22),
                              Wrap(
                                spacing: 28,
                                runSpacing: 18,
                                children: [
                                  _Dado(
                                    titulo: 'Disciplina',
                                    valor: simulado.disciplina,
                                  ),
                                  _Dado(
                                    titulo: 'Turma',
                                    valor: simulado.turma,
                                  ),
                                  _Dado(
                                    titulo: 'Data de aplicação',
                                    valor: _formatarData(
                                      simulado.dataAplicacao,
                                    ),
                                  ),
                                  _Dado(
                                    titulo: 'Professor responsável',
                                    valor: simulado.professorResponsavel,
                                  ),
                                  _Dado(
                                    titulo: 'Total de questões',
                                    valor: '${simulado.quantidadeQuestoes}',
                                  ),
                                  _Dado(
                                    titulo: 'Respostas recebidas',
                                    valor: '${simulado.respostasRecebidas}',
                                  ),
                                ],
                              ),
                              if (simulado.descricao.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'Descrição',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(simulado.descricao),
                              ],
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FormularioSimuladoScreen(
                                            appState: widget.appState,
                                            simulado: simulado,
                                          ),
                                        ),
                                      );
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar simulado'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _alternarStatus(simulado),
                                    icon: Icon(
                                      resultadosLiberados
                                          ? Icons.lock_outline
                                          : Icons.lock_open_outlined,
                                    ),
                                    label: Text(
                                      resultadosLiberados
                                          ? 'Bloquear resultados'
                                          : 'Liberar resultados',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    onPressed: () => _excluir(simulado),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Excluir simulado'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Gabarito cadastrado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Questão',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Gabarito',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Assunto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...simulado.questoes.map(
                              (questao) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text('${questao.numero}'),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        questao.gabarito ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        questao.assunto.isEmpty
                                            ? 'Não informado'
                                            : questao.assunto,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Resumo de respostas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Wrap(
                            spacing: 40,
                            runSpacing: 20,
                            children: [
                              _ResumoItem(
                                icon: Icons.people_alt_outlined,
                                titulo: 'Alunos responderam',
                                valor: '${simulado.respostasRecebidas}',
                              ),
                              const _ResumoItem(
                                icon: Icons.hourglass_empty,
                                titulo: 'Aguardando liberação',
                                valor: '12',
                              ),
                              const _ResumoItem(
                                icon: Icons.check_circle_outline,
                                titulo: 'Resultados liberados',
                                valor: '16',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dado extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Dado({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _ResumoItem({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 30,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              titulo,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }
}