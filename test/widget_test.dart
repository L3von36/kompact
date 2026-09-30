import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kompact/app.dart';
import 'package:kompact/core/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KompactApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  testWidgets('App boots to the dashboard and seeds demo content',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('DONE TODAY'), findsOneWidget);
    expect(find.text('FOCUS NOW'), findsOneWidget);
  });

  testWidgets('Navigation switches to Tasks and Notes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(tester);

    // Narrow layout → bottom navigation bar.
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Search tasks…'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Search notes…'), findsOneWidget);
  });
}
