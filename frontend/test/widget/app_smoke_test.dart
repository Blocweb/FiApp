import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/main.dart';

void main() {
  testWidgets('App inicia sin lanzar excepciones', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FiApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
