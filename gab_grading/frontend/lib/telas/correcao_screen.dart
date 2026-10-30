import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aluno.dart';
import '../models/turma.dart';
import '../routes.dart';
import '../services/turma_service.dart';
import '../widgets/estados_da_tela.dart';

typedef TurmaComAlunos = ({Turma turma, List<Aluno> alunos});

// Corrigir um simulado: escolhe-se o aluno, de qualquer uma das turmas, e daí
// se lançam as respostas dele neste simulado.
class CorrecaoScreen extends StatefulWidget {
  const CorrecaoScreen({super.key, required this.simuladoId});

  final int simuladoId;

  @override
  State<CorrecaoScreen> createState() => _CorrecaoScreenState();
}

class _CorrecaoScreenState extends State<CorrecaoScreen> {
  late Future<List<TurmaComAlunos>> turmas;

  @override
  void initState() {
    super.initState();
    turmas = context.read<TurmaService>().turmasComAlunos();
  }

  void pedirDeNovo() {
    setState(() {
      turmas = context.read<TurmaService>().turmasComAlunos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corrigir: escolha o aluno')),
      body: EstadosDaTela<List<TurmaComAlunos>>(
        pedido: turmas,
        tituloDoErro: 'Não consegui carregar as turmas',
        pedirDeNovo: pedirDeNovo,
        estaVazio: (lista) => lista.every((t) => t.alunos.isEmpty),
        mensagemVazia: 'Cadastre uma turma com alunos (menu Turmas) antes de corrigir.',
        construir: (context, lista) {
          return ListView(
            children: [
              for (final item in lista)
                ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.groups),
                  title: Text(item.turma.nome),
                  subtitle: Text('${item.alunos.length} aluno(s)'),
                  children: [
                    for (final aluno in item.alunos)
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(aluno.nome),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.respostas,
                            arguments: (simuladoId: widget.simuladoId, aluno: aluno),
                          );
                        },
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
