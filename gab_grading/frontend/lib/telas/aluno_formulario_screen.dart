import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aluno.dart';
import '../services/traducao.dart';
import '../services/turma_service.dart';
import '../widgets/confirmar_exclusao.dart';

// Uma tela só para cadastrar e para editar um aluno de uma turma. Editando, a
// tela também tem o Excluir. A turma vem do caminho: o aluno nunca existe fora
// de uma turma.
class AlunoFormularioScreen extends StatefulWidget {
  const AlunoFormularioScreen({super.key, required this.turmaId, this.aluno});

  final int turmaId;

  // O aluno a editar; null é um aluno novo.
  final Aluno? aluno;

  @override
  State<AlunoFormularioScreen> createState() => _AlunoFormularioScreenState();
}

class _AlunoFormularioScreenState extends State<AlunoFormularioScreen> {
  final chave = GlobalKey<FormState>();
  final nome = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    nome.text = widget.aluno?.nome ?? '';
  }

  Future<void> salvar() async {
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    final servico = context.read<TurmaService>();
    try {
      if (widget.aluno == null) {
        await servico.criarAluno(widget.turmaId, nome.text.trim());
      } else {
        await servico.atualizarAluno(widget.turmaId, widget.aluno!.id, nome.text.trim());
      }
    } on ErroDeApi catch (e) {
      setState(() {
        salvando = false;
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> excluir() async {
    final aluno = widget.aluno!;
    final certeza = await confirmarExclusao(
      context,
      'Excluir ${aluno.nome}?',
      'Tem certeza? O aluno sai da turma, e não dá para desfazer pelo app.',
    );
    if (!certeza || !mounted) {
      return;
    }
    try {
      await context.read<TurmaService>().excluirAluno(widget.turmaId, aluno.id);
    } on ErroDeApi catch (e) {
      setState(() {
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.aluno != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar aluno' : 'Novo aluno')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: chave,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nome,
                    decoration: const InputDecoration(
                      labelText: 'Nome do aluno',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor ?? '').trim().isEmpty ? 'Informe o nome do aluno' : null,
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    child: Text(salvando ? 'Salvando...' : 'Salvar'),
                  ),
                  if (editando) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: excluir,
                      icon: const Icon(Icons.delete),
                      label: const Text('Excluir aluno'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
