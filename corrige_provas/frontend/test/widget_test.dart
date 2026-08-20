// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/state/app_state.dart';

void main() {
  testWidgets('CorrigeProvas inicia na tela de login',
      (WidgetTester tester) async {
    final appState = AppState()..carregarDadosFicticios();

    await tester.pumpWidget(
      CorrigeProvasApp(appState: appState),
    );

    expect(find.text('CorrigeProvas'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}