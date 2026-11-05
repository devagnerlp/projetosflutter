import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/turma.dart';
import '../services/traducao.dart';
import '../services/turma_service.dart';
import 'turmas_screen.dart';

// Uma tela só para cadastrar e para editar uma turma: um campo, o nome.
class TurmaFormularioScreen extends StatefulWidget {
  const TurmaFormularioScreen({super.key, this.turma});

  // A turma a editar, que veio nos arguments; null é uma turma nova.
  final Turma? turma;

  @override
  State<TurmaFormularioScreen> createState() => _TurmaFormularioScreenState();
}

class _TurmaFormularioScreenState extends State<TurmaFormularioScreen> {
  final chave = GlobalKey<FormState>();
  final nome = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    nome.text = widget.turma?.nome ?? '';
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
      if (widget.turma == null) {
        await servico.criar(nome.text.trim());
      } else {
        await servico.atualizar(widget.turma!.id, nome.text.trim());
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

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Depois de um F5, o formulário é a primeira tela da pilha: ninguém o abriu.
    if (ModalRoute.of(context)!.isFirst) {
      return const TurmasScreen();
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.turma == null ? 'Nova turma' : 'Editar turma')),
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
                      labelText: 'Nome da turma',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor ?? '').trim().isEmpty ? 'Informe o nome da turma' : null,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
