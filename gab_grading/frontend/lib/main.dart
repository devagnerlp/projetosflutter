import 'package:flutter/material.dart';

import 'telas/login_screen.dart';

void main() {
  runApp(const GabGradingApp());
}

class GabGradingApp extends StatelessWidget {
  const GabGradingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GabGrading',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const LoginScreen(),
    );
  }
}
