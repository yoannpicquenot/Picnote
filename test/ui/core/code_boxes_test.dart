import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('a long press offers Paste, which fills the code from the clipboard', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': 'Ton code : 482913'};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final values = await enter(tester, '');
    await tester.longPress(find.byType(CodeBoxes));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Paste'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(values.last, '482913');
    expect(find.text('Paste'), findsNothing);
  });

  testWidgets('a tap brings the keyboard back after the system hid it, focus kept', (tester) async {
    await enter(tester, '12');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    // The notification shade or another app hides the keyboard; the field keeps focus.
    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byType(CodeBoxes));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('the keyboard comes back when the app resumes', (tester) async {
    await enter(tester, '12');
    await tester.pump();
    tester.testTextInput.hide();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('an invite code, in capitals, without words around it', (tester) async {
    expect((await enter(tester, 'Code : ab3k7r', alphanumeric: true)).last, 'AB3K7R');
  });
}
