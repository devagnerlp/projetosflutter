import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/turma.dart';
import '../routes.dart';
import '../services/turma_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estados_da_tela.dart';

// As turmas de quem está logado. O + cadastra uma turma nova, e o toque abre o
// detalhe dela, onde moram os alunos.
class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  late Future<List<Turma>> turmas;

  @override
  void initState() {
    super.initState();
    turmas = context.read<TurmaService>().listar();
  }

  void pedirDeNovo() {
    setState(() {
      turmas = context.read<TurmaService>().listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      drawer: const AppDrawer(),
      body: EstadosDaTela<List<Turma>>(
        pedido: turmas,
        tituloDoErro: 'Não consegui carregar as turmas',
        pedirDeNovo: pedirDeNovo,
        estaVazio: (lista) => lista.isEmpty,
        mensagemVazia: 'Nenhuma turma ainda. Toque no + para cadastrar.',
        construir: (context, lista) {
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final turma = lista[i];
              return ListTile(
                leading: const Icon(Icons.groups),
                title: Text(turma.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final mudou = await Navigator.pushNamed(context, AppRoutes.turma, arguments: turma.id);
                  if (mudou == true) {
                    pedirDeNovo();
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova turma',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(context, AppRoutes.turmaFormulario);
          if (salvou == true) {
            pedirDeNovo();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
