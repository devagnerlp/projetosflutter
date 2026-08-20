import 'package:flutter/material.dart';

import '../models/simulado.dart';
import 'status_badge.dart';

class SimuladoCard extends StatelessWidget {
  final Simulado simulado;
  final VoidCallback onVisualizar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const SimuladoCard({
    super.key,
    required this.simulado,
    required this.onVisualizar,
    required this.onEditar,
    required this.onExcluir,
  });

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    simulado.titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'visualizar') onVisualizar();
                    if (value == 'editar') onEditar();
                    if (value == 'excluir') onExcluir();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'visualizar',
                      child: Text('Visualizar'),
                    ),
                    PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _InfoItem(
                  icon: Icons.menu_book_outlined,
                  text: simulado.disciplina,
                ),
                _InfoItem(
                  icon: Icons.groups_outlined,
                  text: simulado.turma,
                ),
                _InfoItem(
                  icon: Icons.calendar_month_outlined,
                  text: _formatarData(simulado.dataAplicacao),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: const Icon(Icons.quiz_outlined, size: 18),
                  label: Text('${simulado.quantidadeQuestoes} questões'),
                ),
                Chip(
                  avatar: const Icon(Icons.people_outline, size: 18),
                  label: Text(
                    '${simulado.respostasRecebidas} respostas recebidas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: StatusBadge(status: simulado.status)),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onVisualizar,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Visualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}