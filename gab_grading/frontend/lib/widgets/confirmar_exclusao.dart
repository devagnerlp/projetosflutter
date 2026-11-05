import 'package:flutter/material.dart';

// Pergunta antes de excluir. O diálogo é uma tela por cima, e fecha devolvendo
// um valor: true no Excluir, false no Cancelar, null num toque fora dele. Aqui
// só o true conta como "sim".
Future<bool> confirmarExclusao(BuildContext context, String titulo, String texto) async {
  final certeza = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
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
  return certeza == true;
}
