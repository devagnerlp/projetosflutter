import 'package:flutter/foundation.dart';

import '../data/dados_ficticios.dart';
import '../models/simulado.dart';

class AppState extends ChangeNotifier {
  final List<Simulado> _simulados = [];

  List<Simulado> get simulados => List.unmodifiable(_simulados);

  void carregarDadosFicticios() {
    _simulados
      ..clear()
      ..addAll(dadosFicticios());
    notifyListeners();
  }

  void adicionar(Simulado simulado) {
    _simulados.add(simulado);
    notifyListeners();
  }

  void atualizar(Simulado simulado) {
    final index = _simulados.indexWhere((item) => item.id == simulado.id);

    if (index >= 0) {
      _simulados[index] = simulado;
      notifyListeners();
    }
  }

  void excluir(String id) {
    _simulados.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void alternarStatus(String id) {
    final index = _simulados.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = _simulados[index];

      item.status = item.status == StatusResultados.bloqueados
          ? StatusResultados.liberados
          : StatusResultados.bloqueados;

      notifyListeners();
    }
  }
}