import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/simulado.dart';
import '../routes.dart';
import '../services/simulado_service.dart';
import 'simulados_screen.dart';

// O detalhe de um simulado. Chega só o id, e a tela pede o simulado à API: o
// dado é o de agora, e não o de quando a lista carregou. Daqui, o simulado se
// edita e se exclui; quando um dos dois dá certo, a tela fecha com true.
class SimuladoScreen extends StatefulWidget {
  const SimuladoScreen({super.key, this.id});

  // O id que a rota tirou dos arguments. Sem ele (um F5 aqui apaga os
  // arguments, que moram na memória), a tela mostra a lista.
  final int? id;

  @override
  State<SimuladoScreen> createState() => _SimuladoScreenState();
}

class _SimuladoScreenState extends State<SimuladoScreen> {
  // O pedido do simulado: como o da lista, nasce uma vez, no initState.
  late Future<Simulado> pedido;

  // A recusa da exclusão, para a tela mostrar.
  String? erro;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      pedido = context.read<SimuladoService>().buscar(widget.id!);
    }
  }

  void tentarDeNovo() {
    setState(() {
      pedido = context.read<SimuladoService>().buscar(widget.id!);
    });
  }

  // Abre o formulário com o simulado, para editar. Se ele voltar com true
  // (salvou), esta tela também fecha com true: passa a notícia para a lista.
  Future<void> editar(Simulado simulado) async {
    final salvou = await Navigator.pushNamed(
      context,
      AppRoutes.formulario,
      arguments: simulado,
    );
    if (salvou == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // Pergunta antes de excluir. O diálogo é uma tela por cima, e fecha devolvendo
  // um valor: true no Excluir, false no Cancelar, null num toque fora dele.
  Future<void> excluir(Simulado simulado) async {
    final certeza = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${simulado.identificacao}?'),
        content: const Text(
          'Tem certeza? O simulado sai da sua lista, e não dá para desfazer pelo app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (certeza != true || !mounted) {
      return;
    }
    try {
      await context.read<SimuladoService>().excluir(simulado.id);
    } on ErroDeSimulados catch (e) {
      setState(() {
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) {
      return const SimuladosScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Simulado')),
      body: FutureBuilder<Simulado>(
        future: pedido,
        builder: (context, snapshot) {
          // Os estados da lista, de novo. O vazio não existe aqui: o simulado
          // que sumiu é um 404 da API, e vira erro.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 16),
                  const Text('Não consegui carregar o simulado'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: tentarDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            );
          }
          final simulado = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Identificação'),
                subtitle: Text(simulado.identificacao),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Data de aplicação'),
                subtitle: Text(simulado.dataFormatada),
              ),
              ListTile(
                leading: Icon(simulado.ativo ? Icons.check_circle : Icons.block),
                title: const Text('Situação'),
                subtitle: Text(simulado.ativo ? 'Ativo' : 'Inativo'),
              ),
              const SizedBox(height: 16),
              // Editar e Excluir: o simulado já está na mão, e é o de agora.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => editar(simulado),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => excluir(simulado),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
