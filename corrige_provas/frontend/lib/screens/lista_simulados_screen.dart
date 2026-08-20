import 'package:flutter/material.dart';

import '../models/simulado.dart';
import '../state/app_state.dart';
import '../widgets/confirmacao_dialog.dart';
import '../widgets/simulado_card.dart';
import 'detalhe_simulado_screen.dart';
import 'formulario_simulado_screen.dart';
import 'login_screen.dart';

class ListaSimuladosScreen extends StatefulWidget {
  final AppState appState;
  final String? mensagemInicial;

  const ListaSimuladosScreen({
    super.key,
    required this.appState,
    this.mensagemInicial,
  });

  @override
  State<ListaSimuladosScreen> createState() => _ListaSimuladosScreenState();
}

class _ListaSimuladosScreenState extends State<ListaSimuladosScreen> {
  final _buscaController = TextEditingController();

  String _busca = '';
  String _disciplina = 'Todas';
  String _turma = 'Todas';
  String _status = 'Todos';

  @override
  void initState() {
    super.initState();

    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mensagemInicial != null && mounted) {
        _mostrarMensagem(widget.mensagemInicial!);
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<Simulado> get _filtrados {
    return widget.appState.simulados.where((simulado) {
      final correspondeBusca =
          simulado.titulo.toLowerCase().contains(_busca);

      final correspondeDisciplina = _disciplina == 'Todas' ||
          simulado.disciplina == _disciplina;

      final correspondeTurma =
          _turma == 'Todas' || simulado.turma == _turma;

      final correspondeStatus = _status == 'Todos' ||
          (_status == 'Bloqueados' &&
              simulado.status == StatusResultados.bloqueados) ||
          (_status == 'Liberados' &&
              simulado.status == StatusResultados.liberados);

      return correspondeBusca &&
          correspondeDisciplina &&
          correspondeTurma &&
          correspondeStatus;
    }).toList();
  }

  Future<void> _excluir(Simulado simulado) async {
    final confirmou = await confirmarExclusao(context);

    if (!confirmou || !mounted) return;

    widget.appState.excluir(simulado.id);
    _mostrarMensagem('Simulado excluído com sucesso.');
  }

  void _sair() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          appState: widget.appState,
          mensagemInicial: 'Sessão encerrada com sucesso.',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final simulados = _filtrados;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meus Simulados'),
            actions: [
              IconButton(
                tooltip: 'Sair',
                onPressed: _sair,
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormularioSimuladoScreen(
                    appState: widget.appState,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Novo Simulado'),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth > 1100
                  ? 1000.0
                  : constraints.maxWidth;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: largura),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      Text(
                        'Olá, Prof. João Silva',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gerencie seus simulados e acompanhe as correções.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _buscaController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar por título...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: Icon(Icons.tune),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _Filtro(
                            label: 'Disciplina',
                            valor: _disciplina,
                            opcoes: const [
                              'Todas',
                              'Matemática',
                              'História',
                            ],
                            onChanged: (value) {
                              setState(() => _disciplina = value!);
                            },
                          ),
                          _Filtro(
                            label: 'Turma',
                            valor: _turma,
                            opcoes: const [
                              'Todas',
                              '1º Ano B',
                              '2º Ano A',
                              '3º Ano A',
                            ],
                            onChanged: (value) {
                              setState(() => _turma = value!);
                            },
                          ),
                          _Filtro(
                            label: 'Resultados',
                            valor: _status,
                            opcoes: const [
                              'Todos',
                              'Bloqueados',
                              'Liberados',
                            ],
                            onChanged: (value) {
                              setState(() => _status = value!);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      if (simulados.isEmpty)
                        const _EstadoVazio()
                      else
                        ...simulados.map(
                          (simulado) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SimuladoCard(
                              simulado: simulado,
                              onVisualizar: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalheSimuladoScreen(
                                      appState: widget.appState,
                                      simuladoId: simulado.id,
                                    ),
                                  ),
                                );
                              },
                              onEditar: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormularioSimuladoScreen(
                                      appState: widget.appState,
                                      simulado: simulado,
                                    ),
                                  ),
                                );
                              },
                              onExcluir: () => _excluir(simulado),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Filtro extends StatelessWidget {
  final String label;
  final String valor;
  final List<String> opcoes;
  final ValueChanged<String?> onChanged;

  const _Filtro({
    required this.label,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        decoration: InputDecoration(labelText: label),
        items: opcoes
            .map(
              (opcao) => DropdownMenuItem(
                value: opcao,
                child: Text(opcao),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum simulado cadastrado ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}