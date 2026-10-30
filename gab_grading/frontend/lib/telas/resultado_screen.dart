import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aluno.dart';
import '../models/resultado.dart';
import '../services/correcao_service.dart';
import '../widgets/estados_da_tela.dart';

// A correção de um aluno em um simulado: a nota, os acertos e os acertos por
// componente curricular (RN-20). Quem calcula é a API; a tela só mostra.
class ResultadoScreen extends StatefulWidget {
  const ResultadoScreen({super.key, required this.simuladoId, required this.aluno});

  final int simuladoId;
  final Aluno aluno;

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen> {
  late Future<Resultado> pedido;

  @override
  void initState() {
    super.initState();
    pedido = context.read<CorrecaoService>().resultado(widget.simuladoId, widget.aluno.id);
  }

  void pedirDeNovo() {
    setState(() {
      pedido = context.read<CorrecaoService>().resultado(widget.simuladoId, widget.aluno.id);
    });
  }

  // A nota como a pessoa lê, com vírgula: 6,67.
  String escreverNota(double nota) => nota.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultado de ${widget.aluno.nome}')),
      body: EstadosDaTela<Resultado>(
        pedido: pedido,
        tituloDoErro: 'Não consegui carregar o resultado',
        pedirDeNovo: pedirDeNovo,
        construir: (context, resultado) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Nota'),
                      Text(
                        escreverNota(resultado.nota),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      Text('${resultado.totalAcertos} de ${resultado.totalQuestoes} acertos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Acertos por componente', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final item in resultado.porComponente)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.componente),
                          Text('${item.acertos}/${item.total}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: item.total == 0 ? 0 : item.acertos / item.total),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
