import 'package:flutter/material.dart';

import '../models/simulado.dart';

class StatusBadge extends StatelessWidget {
  final StatusResultados status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final liberado = status == StatusResultados.liberados;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: liberado
            ? Colors.green.withValues(alpha: .12)
            : Colors.orange.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liberado ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: liberado ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 6),
          Text(
            liberado ? 'Resultados liberados' : 'Resultados bloqueados',
            style: TextStyle(
              color: liberado ? Colors.green.shade700 : Colors.orange.shade800,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}