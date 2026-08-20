import 'package:flutter/material.dart';

import '../models/questao.dart';
import '../models/simulado.dart';
import '../state/app_state.dart';

class FormularioSimuladoScreen extends StatefulWidget {
  final AppState appState;
  final Simulado? simulado;

  const FormularioSimuladoScreen({
    super.key,
    required this.appState,
    this.simulado,
  });

  bool get editando => simulado != null;

  @override
  State<FormularioSimuladoScreen> createState() =>
      _FormularioSimuladoScreenState();
}

class _FormularioSimuladoScreenState
    extends State<FormularioSimuladoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _disciplinaController;
  late final TextEditingController _turmaController;
  late final TextEditingController _descricaoController;

  late DateTime? _dataAplicacao;
  late List<Questao> _questoes;

  @override
  void initState() {
    super.initState();

    final simulado = widget.simulado;

    _tituloController = TextEditingController(text: simulado?.titulo ?? '');
    _disciplinaController =
        TextEditingController(text: simulado?.disciplina ?? '');
    _turmaController = TextEditingController(text: simulado?.turma ?? '');
    _descricaoController =
        TextEditingController(text: simulado?.descricao ?? '');

    _dataAplicacao = simulado?.dataAplicacao;
    _questoes = simulado == null
        ? [Questao(numero: 1)]
        : simulado.questoes.map((questao) => questao.copy()).toList();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _disciplinaController.dispose();
    _turmaController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataAplicacao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (data != null) {
      setState(() => _dataAplicacao = data);
    }
  }

  void _adicionarQuestao() {
    final maiorNumero = _questoes.isEmpty
        ? 0
        : _questoes.map((questao) => questao.numero).reduce(
              (a, b) => a > b ? a : b,
            );

    setState(() {
      _questoes.add(Questao(numero: maiorNumero + 1));
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios.'),
        ),
      );
      return;
    }

    if (_dataAplicacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios.'),
        ),
      );
      return;
    }

    if (_questoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre pelo menos uma questão.'),
        ),
      );
      return;
    }

    final numeros = <int>{};

    for (final questao in _questoes) {
      if (questao.numero <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O número da questão deve ser válido.'),
          ),
        );
        return;
      }

      if (!numeros.add(questao.numero)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Já existe uma questão com esse número.'),
          ),
        );
        return;
      }

      if (questao.gabarito == null ||
          !['A', 'B', 'C', 'D', 'E'].contains(questao.gabarito)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O gabarito deve ser A, B, C, D ou E.'),
          ),
        );
        return;
      }
    }

    final simulado = Simulado(
      id: widget.simulado?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      titulo: _tituloController.text.trim(),
      disciplina: _disciplinaController.text.trim(),
      turma: _turmaController.text.trim(),
      dataAplicacao: _dataAplicacao!,
      descricao: _descricaoController.text.trim(),
      professorResponsavel:
          widget.simulado?.professorResponsavel ?? 'Prof. João Silva',
      respostasRecebidas: widget.simulado?.respostasRecebidas ?? 0,
      status: widget.simulado?.status ?? StatusResultados.bloqueados,
      questoes: _questoes,
    );

    if (widget.editando) {
      widget.appState.atualizar(simulado);
    } else {
      widget.appState.adicionar(simulado);
    }

    Navigator.pop(
      context,
      widget.editando
          ? 'Simulado atualizado com sucesso.'
          : 'Simulado criado com sucesso.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editando ? 'Editar Simulado' : 'Novo Simulado'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dados gerais',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título do simulado *',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o título.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _disciplinaController,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina *',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a disciplina.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _turmaController,
                      decoration: const InputDecoration(
                        labelText: 'Turma *',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a turma.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _selecionarData,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de aplicação *',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        child: Text(
                          _dataAplicacao == null
                              ? 'Selecione uma data'
                              : _formatarData(_dataAplicacao!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição opcional',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gabarito e questões',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _adicionarQuestao,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar questão'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._questoes.asMap().entries.map(
                          (entry) => _QuestaoEditor(
                            key: ValueKey(entry.key),
                            questao: entry.value,
                            onRemover: () {
                              setState(() => _questoes.removeAt(entry.key));
                            },
                          ),
                        ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.editando
                              ? 'Salvar alterações'
                              : 'Salvar simulado',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestaoEditor extends StatefulWidget {
  final Questao questao;
  final VoidCallback onRemover;

  const _QuestaoEditor({
    super.key,
    required this.questao,
    required this.onRemover,
  });

  @override
  State<_QuestaoEditor> createState() => _QuestaoEditorState();
}

class _QuestaoEditorState extends State<_QuestaoEditor> {
  late final TextEditingController _numeroController;
  late final TextEditingController _assuntoController;

  @override
  void initState() {
    super.initState();
    _numeroController =
        TextEditingController(text: widget.questao.numero.toString());
    _assuntoController =
        TextEditingController(text: widget.questao.assunto);
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _assuntoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número *',
                ),
                onChanged: (value) {
                  widget.questao.numero = int.tryParse(value) ?? 0;
                },
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: widget.questao.gabarito,
                decoration: const InputDecoration(
                  labelText: 'Gabarito *',
                ),
                items: ['A', 'B', 'C', 'D', 'E']
                    .map(
                      (letra) => DropdownMenuItem(
                        value: letra,
                        child: Text(letra),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => widget.questao.gabarito = value);
                },
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _assuntoController,
                decoration: const InputDecoration(
                  labelText: 'Assunto opcional',
                ),
                onChanged: (value) => widget.questao.assunto = value,
              ),
            ),
            IconButton(
              tooltip: 'Remover questão',
              color: Colors.red.shade700,
              onPressed: widget.onRemover,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}