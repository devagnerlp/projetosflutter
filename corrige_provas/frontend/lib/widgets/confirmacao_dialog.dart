import 'package:flutter/material.dart';

Future<bool> confirmarExclusao(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Excluir simulado?'),
        content: const Text(
          'Tem certeza de que deseja excluir este simulado? '
          'Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      );
    },
  );

  return resultado ?? false;
}

Future<bool> confirmarBloqueio(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Bloquear resultados?'),
        content: const Text(
          'Os alunos deixarão de visualizar os resultados liberados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      );
    },
  );

  return resultado ?? false;
}