import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/simulado.dart';
import '../routes.dart';
import '../services/simulado_service.dart';
import '../widgets/app_drawer.dart';

// A lista dos simulados de quem está logado, vinda da API. A tela tem quatro
// estados, um de cada vez: carregando, erro, lista vazia e a lista. O + abre
// o formulário de um simulado novo, e o toque, o detalhe (que edita e exclui).
class SimuladosScreen extends StatefulWidget {
  const SimuladosScreen({super.key});

  @override
  State<SimuladosScreen> createState() => _SimuladosScreenState();
}

class _SimuladosScreenState extends State<SimuladosScreen> {
  // O pedido à API: nasce UMA vez, quando a tela nasce, e só é refeito pelo
  // pedirDeNovo. Criado dentro do build, sairia de novo a cada redesenho.
  late Future<List<Simulado>> simulados;

  @override
  void initState() {
    super.initState();
    simulados = context.read<SimuladoService>().listar();
  }

  // Pede a lista de novo: o Tentar de novo, e a volta de uma tela que mudou
  // os simulados (fechou com true), fazem a mesma coisa.
  void pedirDeNovo() {
    setState(() {
      simulados = context.read<SimuladoService>().listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulados')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Simulado>>(
        future: simulados,
        builder: (context, snapshot) {
          // 1. Carregando: a resposta ainda não chegou.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Erro: a API recusou, ou nem respondeu.
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 16),
                  const Text('Não consegui carregar os simulados'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: pedirDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            );
          }
          final lista = snapshot.data!;
          // 3. Vazia: o pedido deu certo, mas não há simulado nenhum.
          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum simulado ainda.'));
          }
          // 4. A lista: um ListTile por simulado. O toque abre o detalhe e leva
          // só o id: a tela do simulado busca o simulado de agora na API. O
          // await espera o detalhe fechar: com true (editou ou excluiu), a
          // lista pede de novo.
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final simulado = lista[i];
              return ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(simulado.identificacao),
                subtitle: Text(simulado.dataFormatada),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final mudou = await Navigator.pushNamed(
                    context,
                    AppRoutes.simulado,
                    arguments: simulado.id,
                  );
                  if (mudou == true) {
                    pedirDeNovo();
                  }
                },
              );
            },
          );
        },
      ),
      // O + abre o formulário vazio. Ele fecha com true quando salvou: aí, a
      // lista pede de novo, e o simulado novo aparece.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo simulado',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(context, AppRoutes.formulario);
          if (salvou == true) {
            pedirDeNovo();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
