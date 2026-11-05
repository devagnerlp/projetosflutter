import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aluno.dart';
import '../models/turma.dart';
import '../routes.dart';
import '../services/traducao.dart';
import '../services/turma_service.dart';
import '../widgets/confirmar_exclusao.dart';
import '../widgets/estados_da_tela.dart';

// O detalhe de uma turma, com os alunos dela. Chega só o id, e a tela pede a
// turma e os alunos à API. Editar ou excluir a turma fecha a tela com true (a
// lista pede de novo); mexer nos alunos só recarrega esta tela.
class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key, required this.id});

  final int id;

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  late Future<({Turma turma, List<Aluno> alunos})> pedido;
  String? erro;

  @override
  void initState() {
    super.initState();
    pedido = context.read<TurmaService>().detalhe(widget.id);
  }

  void pedirDeNovo() {
    setState(() {
      pedido = context.read<TurmaService>().detalhe(widget.id);
    });
  }

  Future<void> editar(Turma turma) async {
    final salvou = await Navigator.pushNamed(context, AppRoutes.turmaFormulario, arguments: turma);
    if (salvou == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> excluir(Turma turma) async {
    final certeza = await confirmarExclusao(
      context,
      'Excluir ${turma.nome}?',
      'Tem certeza? A turma e os alunos dela saem da sua lista, e não dá para desfazer pelo app.',
    );
    if (!certeza || !mounted) {
      return;
    }
    try {
      await context.read<TurmaService>().excluir(turma.id);
    } on ErroDeApi catch (e) {
      setState(() {
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // Abre o formulário do aluno (sem aluno, cria; com ele, edita) e recarrega.
  Future<void> abrirAluno(Turma turma, [Aluno? aluno]) async {
    final mudou = await Navigator.pushNamed(
      context,
      AppRoutes.alunoFormulario,
      arguments: (turmaId: turma.id, aluno: aluno),
    );
    if (mudou == true) {
      pedirDeNovo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turma')),
      body: EstadosDaTela<({Turma turma, List<Aluno> alunos})>(
        pedido: pedido,
        tituloDoErro: 'Não consegui carregar a turma',
        pedirDeNovo: pedirDeNovo,
        construir: (context, dados) {
          final turma = dados.turma;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Nome'),
                subtitle: Text(turma.nome),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => editar(turma),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => excluir(turma),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 16),
                Text(erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ],
              const Divider(height: 32),
              ListTile(
                title: const Text('Alunos', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: TextButton.icon(
                  onPressed: () => abrirAluno(turma),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Adicionar aluno'),
                ),
              ),
              if (dados.alunos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Nenhum aluno ainda.')),
                ),
              for (final aluno in dados.alunos)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(aluno.nome),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => abrirAluno(turma, aluno),
                ),
            ],
          );
        },
      ),
    );
  }
}
