import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/ui/core/ui/auth_shell.dart';

void main() {
  Future<List<String>> enter(WidgetTester tester, String text, {bool alphanumeric = false}) async {
    final values = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CodeBoxes(
              value: values.isEmpty ? '' : values.last,
              label: 'Code',
              alphanumeric: alphanumeric,
              onChanged: (v) => setState(() => values.add(v)),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), text);
    return values;
  }

  testWidgets('a code pasted with words around it keeps the code', (tester) async {
    expect((await enter(tester, 'Ton code : 123456 (valable 10 min)')).last, '123456');
  });

  testWidgets('a code pasted over a started one replaces it', (tester) async {
    final values = await enter(tester, '12');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '12654321');
    expect(values.last, '654321');
  });

  testWidgets('an invite code, in capitals, without words around it', (tester) async {
    expect((await enter(tester, 'Code : ab3k7r', alphanumeric: true)).last, 'AB3K7R');
  });
}
