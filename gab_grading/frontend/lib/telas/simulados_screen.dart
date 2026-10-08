import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

// Um lugar reservado: a listagem dos Simulados chega adiante.
class SimuladosScreen extends StatelessWidget {
  const SimuladosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulados')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 56),
            SizedBox(height: 16),
            Text('A listagem dos simulados chega adiante.'),
          ],
        ),
      ),
    );
  }
}
