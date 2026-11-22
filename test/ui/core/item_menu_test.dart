import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/activity.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/core/themes/colors.dart';
import 'package:picnote/ui/core/ui/controls.dart';
import 'package:picnote/ui/core/ui/item_menu.dart';
import 'package:picnote/ui/core/ui/settings_rows.dart';

import '../../../testing/models/task_list.dart';

void main() {
  /// Opens the menu; the result says what it popped with.
  Future<ItemMenuAction? Function()> pumpMenu(
    WidgetTester tester, {
    bool isNote = false,
    bool shared = true,
    String? creatorId,
    bool? pinned,
    bool homeFull = false,
    Future<void> Function(bool pinned)? onSetPinned,
    bool canShare = true,
    bool canDelete = true,
    List<Activity> changes = const [],
  }) async {
    ItemMenuAction? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => picked = await showModalBottomSheet<ItemMenuAction>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ItemMenuSheet(
                    title: 'Courses.',
                    isNote: isNote,
                    changes: Future.value(changes),
                    meId: kMe.id,
                    members: const [kMe, kPartner],
                    shared: shared,
                    theme: ListTheme.app,
                    creatorId: creatorId,
                    pinned: pinned,
                    homeFull: homeFull,
                    onSetPinned: onSetPinned,
                    canShare: canShare,
                    canDelete: canDelete,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => picked;
  }

  testWidgets('a list: pinned and shared switches, delete, then who created it', (tester) async {
    final picked = await pumpMenu(
      tester,
      pinned: true,
      creatorId: kMe.id,
      changes: [
        Activity(
          isNote: false,
          itemId: 'c',
          actorId: kPartner.id,
          verb: ActivityVerb.add,
          item: 'Café',
          at: DateTime.now(),
        ),
      ],
    );

    expect(find.text('Épinglée sur l’accueil'), findsOneWidget);
    expect(find.text('Visible sur ton accueil'), findsOneWidget);
    expect(find.text('Liste partagée'), findsOneWidget);
    expect(find.text('Yoann la voit et peut la modifier'), findsOneWidget);
    expect(find.byType(PnToggle), findsNWidgets(2));
    expect(find.text('Yoann a ajouté « Café »'), findsOneWidget);
    expect(find.text('Créée par toi'), findsOneWidget);

    await tester.tap(find.text('Épinglée sur l’accueil'));
    await tester.pumpAndSettle();
    // No onSetPinned here: the screen handles it.
    expect(picked(), ItemMenuAction.togglePin);
  });

  testWidgets('room on home: the switch pins in place, the menu stays open', (tester) async {
    final calls = <bool>[];
    final picked = await pumpMenu(tester, pinned: false, onSetPinned: (v) async => calls.add(v));
    expect(find.text('Seulement dans « Toutes les listes »'), findsOneWidget);

    await tester.tap(find.text('Épinglée sur l’accueil'));
    await tester.pumpAndSettle();
    expect(calls, [true]);
    expect(find.text('Visible sur ton accueil'), findsOneWidget);
    expect(tester.widget<PnToggle>(find.byType(PnToggle).first).on, isTrue);
    expect(picked(), isNull, reason: 'still open');

    // And back.
    await tester.tap(find.text('Épinglée sur l’accueil'));
    await tester.pumpAndSettle();
    expect(calls, [true, false]);
    expect(find.text('Seulement dans « Toutes les listes »'), findsOneWidget);
  });

  testWidgets('home full: pinning leaves the menu, to make room first', (tester) async {
    final calls = <bool>[];
    final picked = await pumpMenu(tester, pinned: false, homeFull: true, onSetPinned: (v) async => calls.add(v));

    await tester.tap(find.text('Épinglée sur l’accueil'));
    await tester.pumpAndSettle();
    expect(picked(), ItemMenuAction.togglePin);
    expect(calls, isEmpty);
  });

  testWidgets('a note the other wrote: sharing and deleting greyed, with the reason', (tester) async {
    final picked = await pumpMenu(tester, isNote: true, creatorId: kPartner.id, canShare: false, canDelete: false);

    expect(find.text('Réservé à Yoann, qui l’a créée'), findsNWidgets(2));
    final rows = tester.widgetList<SettingsRow>(find.byType(SettingsRow)).toList();
    expect(rows.map((r) => r.dimmed), [true, true]);

    // Greyed rows do nothing.
    await tester.tap(find.text('Supprimer la note'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer la note'), findsOneWidget);
    expect(picked(), isNull);
  });
}
