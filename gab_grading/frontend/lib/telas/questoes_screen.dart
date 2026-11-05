import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/questao.dart';
import '../routes.dart';
import '../services/questao_service.dart';
import '../widgets/estados_da_tela.dart';

// As questões de um simulado, com a alternativa certa de cada uma (o gabarito).
// O + cadastra uma questão nova, e o toque abre a edição. A questão não se
// exclui (RN-13): ela pesa na nota dos alunos.
class QuestoesScreen extends StatefulWidget {
  const QuestoesScreen({super.key, required this.simuladoId});

  final int simuladoId;

  @override
  State<QuestoesScreen> createState() => _QuestoesScreenState();
}

class _QuestoesScreenState extends State<QuestoesScreen> {
  late Future<List<Questao>> questoes;

  @override
  void initState() {
    super.initState();
    questoes = context.read<QuestaoService>().listar(widget.simuladoId);
  }

  void pedirDeNovo() {
    setState(() {
      questoes = context.read<QuestaoService>().listar(widget.simuladoId);
    });
  }

  // Abre o formulário (sem questão, cria; com ela, edita) e, se salvou, pede de novo.
  Future<void> abrirFormulario([Questao? questao]) async {
    final salvou = await Navigator.pushNamed(
      context,
      AppRoutes.questaoFormulario,
      arguments: (simuladoId: widget.simuladoId, questao: questao),
    );
    if (salvou == true) {
      pedirDeNovo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questões')),
      body: EstadosDaTela<List<Questao>>(
        pedido: questoes,
        tituloDoErro: 'Não consegui carregar as questões',
        pedirDeNovo: pedirDeNovo,
        estaVazio: (lista) => lista.isEmpty,
        mensagemVazia: 'Nenhuma questão ainda. Toque no + para cadastrar.',
        construir: (context, lista) {
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final questao = lista[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${questao.numero}')),
                title: Text(questao.componente),
                subtitle: questao.conteudo == null ? null : Text(questao.conteudo!),
                trailing: Chip(label: Text('Gabarito: ${questao.alternativaCorreta}')),
                onTap: () => abrirFormulario(questao),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova questão',
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
