import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picnote/config/dependencies.dart';
import 'package:picnote/config/local.dart';
import 'package:picnote/data/repositories/household/household_repository_local.dart';
import 'package:picnote/data/repositories/live/live_repository.dart';
import 'package:picnote/data/repositories/note/note_repository.dart';
import 'package:picnote/domain/models/live.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/ui/home/widgets/home_screen.dart';
import 'package:picnote/data/repositories/list/list_repository.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/main.dart';
import 'package:picnote/ui/core/themes/colors.dart';
import 'package:picnote/routing/routes.dart';
import 'package:picnote/ui/core/ui/buttons.dart';
import 'package:picnote/ui/core/ui/controls.dart';
import 'package:picnote/ui/core/ui/list_sheet.dart';
import 'package:picnote/ui/core/ui/selection_handles.dart';
import 'package:picnote/ui/all_lists/widgets/all_lists_screen.dart';
import 'package:picnote/ui/list/widgets/list_screen.dart';
import 'package:picnote/ui/core/ui/sheet.dart';
import 'package:picnote/ui/core/ui/task_row.dart';
import 'package:picnote/ui/note/widgets/format_bar.dart';
import 'package:picnote/ui/note/widgets/block_menu.dart';
import 'package:picnote/ui/note/widgets/note_editor.dart';
import 'package:provider/provider.dart';

/// Renders every in-app screen with the design board's demo data, on a
/// phone and on a tablet, to catch layout errors.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<GoRouter> pumpApp(WidgetTester tester, Size size, {bool animations = false, double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // A test may end with a sheet still open, which never closes.
    openSheets.value = 0;
    final repositories = demoRepositories();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: !animations, textScaler: TextScaler.linear(textScale)),
        child: MultiProvider(
          providers: providers(repositories),
          child: PicnoteApp(repositories: repositories, splash: false),
        ),
      ),
    );
    await settle(tester);
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  Finder labeled(String label) => find
      .byWidgetPredicate(
        (w) => (w is Pressable && w.semanticLabel == label) || (w is Semantics && w.properties.label == label),
      )
      .first;

  /// "+" then "New list" or "New note" in its menu.
  Future<void> startNew(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Ajouter'));
    await settle(tester);
    await tester.tap(find.text(item));
    await settle(tester);
  }

  for (final (device, size, scale) in [
    ('phone', const Size(390, 844), 1.0),
    ('tablet', const Size(768, 1024), 1.0),
    // Larger system text, as on many phones.
    ('phone with large text', const Size(390, 844), 1.3),
  ]) {
    testWidgets('every screen renders on a $device', (tester) async {
      final router = await pumpApp(tester, size, textScale: scale);
      expect(find.text('Salut Mel,'), findsOneWidget);

      for (final route in [
        Routes.list('c'),
        Routes.list('b'),
        Routes.lists,
        Routes.notes,
        Routes.note('ca'),
        Routes.note('mo'),
        Routes.settings,
        Routes.account,
        Routes.notifications,
        Routes.home,
      ]) {
        router.go(route);
        await settle(tester);
        final e = tester.takeException();
        if (e != null) fail('$route: ${e is FlutterError ? e.toStringDeep() : e}');
      }
    });
  }

  testWidgets('a list shows its tasks and can be shared or made personal', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.list('c'));
    await settle(tester);

    expect(find.text('Courses.'), findsOneWidget);
    expect(find.text('Tomates'), findsOneWidget);
    // Set, so no "Deadline" pill.
    expect(find.text('Échéance'), findsNothing);

    // The "⋯" menu shows whether it is shared, with a switch, and the
    // latest changes; the switch asks for confirmation.
    await tester.tap(labeled('Options de la liste'));
    await settle(tester);
    expect(find.text('Dernières modifs'), findsOneWidget);
    expect(find.text('Yoann a ajouté « Café »'), findsOneWidget);
    expect(find.text('Yoann la voit et peut la modifier'), findsOneWidget);

    await tester.tap(find.text('Liste partagée'));
    await settle(tester);
    expect(find.text('Passer en perso ?'), findsOneWidget);

    await tester.tap(find.text('Passer en perso'));
    await settle(tester);
    expect(find.text('Liste passée en perso'), findsOneWidget);
  });

  testWidgets('the avatars open who is here, with each one’s latest change', (tester) async {
    await pumpApp(tester, const Size(390, 844));

    await tester.tap(labeled('Foyer et réglages'));
    await settle(tester);
    expect(find.text('Mel (toi)'), findsOneWidget);
    // The demo edit is 5 h old, so between midnight and 5 am it was yesterday.
    final now = DateTime.now();
    final fiveHoursAgo = now.subtract(const Duration(hours: 5));
    final ago = fiveHoursAgo.day == now.day ? 'il y a 5 h' : 'hier';
    expect(find.text('Tu as modifié « Courses », $ago'), findsOneWidget);
    expect(find.text('Yoann'), findsOneWidget);

    await tester.tap(find.text('Réglages'));
    await settle(tester);
    expect(find.text('Réglages.'), findsOneWidget);
  });

  testWidgets('all lists: pinned ones show on home, home holds 4', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.lists);
    await settle(tester);
    expect(find.text('Épinglées.'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('Autres listes.'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await settle(tester);
    expect(find.text('L’accueil est plein. Retire une liste pour en épingler une autre.'), findsOneWidget);

    await tester.tap(labeled('Désépingler Courses'));
    await settle(tester);
    expect(find.text('3/4'), findsOneWidget);
    await tester.tap(labeled('Épingler Livres'));
    await settle(tester);
    expect(find.text('4/4'), findsOneWidget);

    router.go(Routes.home);
    await settle(tester);
    expect(find.text('Livres.'), findsOneWidget);
    expect(find.text('Courses.'), findsNothing);
  });

  testWidgets('a pinned list just done offers to unpin it', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.list('d'));
    await settle(tester);

    for (final title in ['Acheter des fleurs', 'Mettre le vin au frais']) {
      await tester.tap(
        find.descendant(
          of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
          matching: find.byType(PnCheck),
        ),
      );
      await settle(tester);
    }
    expect(find.text('« Dîner » est terminée. La désépingler ?'), findsOneWidget);

    await tester.tap(find.text('Désépingler'));
    await settle(tester);
    router.go(Routes.home);
    await settle(tester);
    expect(find.text('Dîner.'), findsNothing);
  });

  testWidgets('the "+" opens a menu, then the new list sheet', (tester) async {
    await pumpApp(tester, const Size(390, 844));

    await startNew(tester, 'Nouvelle liste');
    expect(find.text('Nouvelle liste.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Pharmacie');
    await tester.pump();
    await tester.tap(find.text('Créer la liste'));
    await settle(tester);
    expect(find.text('Pharmacie.'), findsOneWidget);
    expect(find.text('Écris ton premier élément…'), findsOneWidget);
  });

  testWidgets('the icon and color picker opens inside the sheet', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await startNew(tester, 'Nouvelle liste');

    final titleBefore = tester.getTopLeft(find.text('Nouvelle liste.'));
    await tester.tap(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Changer l’icône et la couleur'),
    );
    await settle(tester);

    expect(find.text('Couleur'), findsOneWidget);
    // All of it on screen: it opens above the tile when there is no room below.
    final picker = tester.getRect(find.byType(IconColorPicker));
    expect(picker.top, greaterThanOrEqualTo(0));
    expect(picker.bottom, lessThanOrEqualTo(844));
    // The keyboard closed so that it doesn't hide the bottom of the picker.
    expect(tester.widgetList<EditableText>(find.byType(EditableText)).any((e) => e.focusNode.hasFocus), isFalse);
    // The sheet grew to make room for it, under the name.
    expect(tester.getTopLeft(find.text('Qui la voit')).dy, greaterThan(picker.bottom));
    expect(tester.getTopLeft(find.text('Nouvelle liste.')).dy, lessThan(titleBefore.dy));
    expect(tester.takeException(), isNull);

    // Tapping outside closes it.
    await tester.tap(find.text('Nouvelle liste.'));
    await settle(tester);
    expect(find.text('Couleur'), findsNothing);
    expect(find.text('Nouvelle liste.'), findsOneWidget);
  });

  testWidgets('a list fades in over its card, and back', (tester) async {
    await pumpApp(tester, const Size(390, 844), animations: true);
    await tester.pump(const Duration(seconds: 1));
    // Halfway through a fade, some page is see-through.
    bool fading() => tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .any((f) => f.opacity.value > 0.05 && f.opacity.value < 0.95);

    await tester.tap(find.text('Courses.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // (The mascot blinks forever, so no pumpAndSettle.)
    expect(fading(), isTrue);
    expect(find.byType(Hero), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tomates'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Inside a list, the bottom bar is hidden.
    final bar = find.ancestor(of: find.text('Listes'), matching: find.byType(IgnorePointer));
    expect(tester.widget<IgnorePointer>(bar.first).ignoring, isTrue);

    await tester.tap(find.text('Accueil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(fading(), isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Salut Mel,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sheet being filled in cannot be swiped away', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await startNew(tester, 'Nouvelle liste');
    await tester.enterText(find.byType(TextField).first, 'Pharmacie');

    await tester.fling(find.text('Nouvelle liste.'), const Offset(0, 500), 2000);
    await settle(tester);
    expect(find.text('Nouvelle liste.'), findsOneWidget);
    expect(find.text('Pharmacie'), findsOneWidget);
  });

  testWidgets('a note fades in, and every motion runs cleanly', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844), animations: true);
    Future<void> wait() => tester.pump(const Duration(seconds: 1));
    await wait();

    router.go(Routes.notes);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);
    await wait();

    await tester.tap(find.text('Voyage au Canada.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(Hero), findsNothing);
    await wait();
    expect(find.textContaining('Lieux à visiter', findRichText: true), findsOneWidget);

    for (final route in [Routes.notes, Routes.settings, Routes.account, Routes.settings, Routes.lists, Routes.home]) {
      router.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await wait();
      final e = tester.takeException();
      if (e != null) fail('$route: $e');
    }
  });

  testWidgets('a list is edited one setting at a time, its menu deletes with undo', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.list('m'));
    await settle(tester);
    // "Maison" has no deadline and no reminder.
    expect(find.text('Échéance'), findsOneWidget);
    expect(find.text('Pas de rappel'), findsOneWidget);

    // The name is renamed in place; an empty name falls back to "Liste".
    await tester.tap(find.text('Maison.'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '  Appart  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('Appart.'), findsOneWidget);
    await tester.tap(find.text('Appart.'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('Liste.'), findsOneWidget);

    // The deadline pill opens "Échéance."
    await tester.tap(find.text('Échéance'));
    await settle(tester);
    expect(find.text('Échéance.'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('Échéance'), findsNothing);

    // The reminder pill opens the reminder sheet; the list is shared.
    await tester.tap(find.text('Pas de rappel'));
    await settle(tester);
    expect(find.text('Toi et Yoann recevez une notification.'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('Pas de rappel'), findsNothing);

    // The icon tile opens the color + icon popover; a pick saves at once.
    await tester.tap(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Changer l’icône et la couleur'),
    );
    await settle(tester);
    expect(find.text('Couleur'), findsOneWidget);
    await tester.tapAt(const Offset(200, 800));
    await settle(tester);
    expect(find.text('Couleur'), findsNothing);

    await tester.tap(labeled('Options de la liste'));
    await settle(tester);
    await tester.tap(find.text('Supprimer la liste'));
    await settle(tester);
    expect(find.text('Liste supprimée'), findsOneWidget);
    expect(find.text('Salut Mel,'), findsOneWidget);
  });

  testWidgets('tapping another task moves the editing to it', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.list('c'));
    await settle(tester);

    await tester.tap(find.text('Tomates'));
    await settle(tester);
    expect(find.byType(TextField), findsWidgets);
    await tester.tap(find.text('Café'));
    await settle(tester);

    final focused = tester.widgetList<EditableText>(find.byType(EditableText)).where((e) => e.focusNode.hasFocus);
    expect(focused.single.controller.text, 'Café');
  });

  testWidgets('a selection spans several lines of a note, and the bar bolds all of it', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);
    expect(find.byType(FormatBar), findsNothing);

    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);
    final end = editor.controller.document.length - 1;
    editor.controller.updateSelection(TextSelection(baseOffset: 0, extentOffset: end), ChangeSource.local);
    await settle(tester);
    expect(find.byType(FormatBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.format_bold_rounded));
    await settle(tester);
    List<NoteBlock> saved() =>
        tester.element(find.byType(NoteEditor)).read<NoteRepository>().notes.firstWhere((n) => n.id == 'mo').blocks;
    // Every line, all of its text, and still the same kinds of line.
    expect(saved().map((b) => b.styles), [
      for (final b in saved()) [StyleRange(0, b.text.length, InlineStyle.bold)],
    ]);
    expect(saved().map((b) => b.type), [NoteBlockType.text, NoteBlockType.todo, NoteBlockType.todo]);

    // A second tap takes it off.
    await tester.tap(find.byIcon(Icons.format_bold_rounded));
    await settle(tester);
    expect(saved().every((b) => b.styles.isEmpty), isTrue);

    // With no selection, the bar stays: B turns bold on for what is typed
    // next, and off again.
    editor.controller.updateSelection(const TextSelection.collapsed(offset: 3), ChangeSource.local);
    await settle(tester);
    expect(find.byType(FormatBar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.format_bold_rounded));
    await settle(tester);
    editor.controller.replaceText(3, 0, 'gras', const TextSelection.collapsed(offset: 7));
    await tester.tap(find.byIcon(Icons.format_bold_rounded));
    await settle(tester);
    editor.controller.replaceText(7, 0, 'fin', const TextSelection.collapsed(offset: 10));
    await settle(tester);
    expect(saved().first.styles, [const StyleRange(3, 7, InlineStyle.bold)]);

    // Unfocused, no bar.
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    expect(find.byType(FormatBar), findsNothing);
  });

  testWidgets('the housemate’s typing shows live: in a note with their cursor, and in a list', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final live = tester.element(find.byType(Scaffold).first).read<LiveRepository>() as LiveRepositoryLocal;
    final yoann = HouseholdRepositoryLocal.partner;

    router.go(Routes.note('mo'));
    await settle(tester);
    live.receiveNote(
      'mo',
      LiveNote(
        userId: yoann.id,
        title: 'Papiers moto',
        blocks: const [NoteBlock(id: 'x', text: 'Carte grise')],
        cursor: 5,
      ),
    );
    await settle(tester);
    expect(find.textContaining('Carte grise', findRichText: true), findsOneWidget);
    expect(find.text('Yoann écrit…'), findsOneWidget);
    // The name above their cursor.
    expect(find.text('Yoann'), findsOneWidget);

    // They stopped: all gone after a few seconds.
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    expect(find.text('Yoann écrit…'), findsNothing);

    router.go(Routes.list('d'));
    await settle(tester);
    live.receiveDraft('d', LiveDraft(userId: yoann.id, text: 'Glaçons'));
    await settle(tester);
    expect(find.byType(DraftTaskRow), findsOneWidget);
    expect(find.text('Glaçons'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('typing in a note too, the housemate’s typing comes in once this user pauses', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final live = tester.element(find.byType(Scaffold).first).read<LiveRepository>() as LiveRepositoryLocal;
    final yoann = HouseholdRepositoryLocal.partner;
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);
    editor.controller.replaceText(0, 0, 'A', const TextSelection.collapsed(offset: 1));
    final mine = editor.controller.document.toPlainText();

    live.receiveNote(
      'mo',
      LiveNote(
        userId: yoann.id,
        title: 'Papiers moto',
        blocks: const [NoteBlock(id: 'x', text: 'Carte grise')],
        cursor: 5,
      ),
    );
    await tester.pump();
    expect(editor.controller.document.toPlainText(), mine, reason: 'not while this user types');
    await tester.pump(const Duration(seconds: 1));
    expect(editor.controller.document.toPlainText(), 'Carte grise\n');
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('"/" on a new line opens the block menu, which turns the line into a heading', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);

    final end = editor.controller.document.length - 1;
    editor.controller.replaceText(end, 0, '\n', TextSelection.collapsed(offset: end + 1));
    editor.pickBlock(NoteBlockType.text);
    editor.controller.replaceText(end + 1, 0, '/tit', TextSelection.collapsed(offset: end + 5));
    await settle(tester);
    expect(find.byType(BlockMenu), findsOneWidget);
    expect(find.text('Liste à puces'), findsNothing, reason: 'filtered by what follows the "/"');

    await tester.tap(find.text('Titre 2'));
    await settle(tester);
    expect(find.byType(BlockMenu), findsNothing);
    final blocks = tester
        .element(find.byType(NoteEditor))
        .read<NoteRepository>()
        .notes
        .firstWhere((n) => n.id == 'mo')
        .blocks;
    expect(blocks.last.type, NoteBlockType.heading);
    expect(blocks.last.level, 2);
    expect(blocks.last.text, isEmpty);
  });

  testWidgets('Enter at the end of a heading goes on in plain text', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('ca'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);

    final heading = 'Lieux à visiter';
    final end = editor.controller.document.toPlainText().indexOf(heading) + heading.length;
    editor.controller.updateSelection(TextSelection.collapsed(offset: end), ChangeSource.local);
    editor.setHeadingColor(HeadingColor.sage);
    await settle(tester);
    // As a keyboard sends it when Enter also commits the word being typed.
    editor.controller.replaceText(end, 0, 's\n', TextSelection.collapsed(offset: end + 2));
    await settle(tester);
    editor.controller.replaceText(end + 2, 0, 'Québec', TextSelection.collapsed(offset: end + 8));
    await settle(tester);

    final blocks = tester
        .element(find.byType(NoteEditor))
        .read<NoteRepository>()
        .notes
        .firstWhere((n) => n.id == 'ca')
        .blocks;
    final i = blocks.indexWhere((b) => b.text == 'Québec');
    expect((blocks[i - 1].type, blocks[i - 1].text), (NoteBlockType.heading, '${heading}s'));
    expect(blocks[i].type, NoteBlockType.text);
    expect(editor.controller.document.collectStyle(end + 2, 6).attributes, isEmpty, reason: 'not in the heading color');
  });

  testWidgets('"- " at the start of a line makes it a bullet', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);

    final end = editor.controller.document.length - 1;
    editor.controller.replaceText(end, 0, '\n', TextSelection.collapsed(offset: end + 1));
    editor.pickBlock(NoteBlockType.text);
    editor.controller.replaceText(end + 1, 0, '- ', TextSelection.collapsed(offset: end + 3));
    await settle(tester);
    editor.controller.replaceText(end + 1, 0, 'Pain', TextSelection.collapsed(offset: end + 5));
    await settle(tester);
    final blocks = tester
        .element(find.byType(NoteEditor))
        .read<NoteRepository>()
        .notes
        .firstWhere((n) => n.id == 'mo')
        .blocks;
    expect((blocks.last.type, blocks.last.text), (NoteBlockType.bullet, 'Pain'));
  });

  testWidgets('Markdown from the keyboard clipboard is read like a paste', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);

    // Gboard's clipboard chip sends the whole text as one typed insert.
    final end = editor.controller.document.length - 1;
    const markdown = '# Bergen\n\nDu **10** au 18.\n\n| Jour | Étapes |\n|---|---|\n| **Mer. 10** | Train |\n';
    editor.controller.replaceText(end, 0, '\n$markdown', TextSelection.collapsed(offset: end + markdown.length + 1));
    await settle(tester);
    final blocks = tester
        .element(find.byType(NoteEditor))
        .read<NoteRepository>()
        .notes
        .firstWhere((n) => n.id == 'mo')
        .blocks;
    final pasted = blocks.skipWhile((b) => b.text != 'Bergen').toList();
    expect(pasted.map((b) => (b.type, b.text)).take(2), [
      (NoteBlockType.heading, 'Bergen'),
      (NoteBlockType.text, 'Du 10 au 18.'),
    ]);
    expect(pasted[2].type, NoteBlockType.table);
    expect(pasted[2].cells, [
      ['Jour', 'Étapes'],
      ['Mer. 10', 'Train'],
    ]);
  });

  group('bullet lists', () {
    /// A note ending with the bullets "Pain" and "Lait", the caret at the
    /// end of "Pain"; returns the editor and where "Pain" starts.
    Future<(NoteEditorState, int)> twoBullets(WidgetTester tester) async {
      final router = await pumpApp(tester, const Size(390, 844));
      router.go(Routes.note('mo'));
      await settle(tester);
      final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
      await tester.tap(find.byType(QuillEditor));
      await settle(tester);
      final c = editor.controller;
      final end = c.document.length - 1;
      c.replaceText(end, 0, '\n', TextSelection.collapsed(offset: end + 1));
      editor.pickBlock(NoteBlockType.bullet);
      c.replaceText(end + 1, 0, 'Pain', TextSelection.collapsed(offset: end + 5));
      c.replaceText(end + 5, 0, '\n', TextSelection.collapsed(offset: end + 6));
      c.replaceText(end + 6, 0, 'Lait', TextSelection.collapsed(offset: end + 10));
      c.updateSelection(TextSelection.collapsed(offset: end + 5), ChangeSource.local);
      await settle(tester);
      return (editor, end + 1);
    }

    List<(NoteBlockType, String)> tail(WidgetTester tester, int n) {
      final blocks = tester
          .element(find.byType(NoteEditor))
          .read<NoteRepository>()
          .notes
          .firstWhere((n) => n.id == 'mo')
          .blocks;
      return [for (final b in blocks.skip(blocks.length - n)) (b.type, b.text)];
    }

    testWidgets('Enter twice, even mid-list, ends the item on a plain line', (tester) async {
      final (editor, pain) = await twoBullets(tester);
      final c = editor.controller;
      c.replaceText(pain + 4, 0, '\n', TextSelection.collapsed(offset: pain + 5));
      await settle(tester);
      c.replaceText(pain + 5, 0, '\n', TextSelection.collapsed(offset: pain + 6));
      await settle(tester);
      expect(tail(tester, 3), [
        (NoteBlockType.bullet, 'Pain'),
        (NoteBlockType.text, ''),
        (NoteBlockType.bullet, 'Lait'),
      ]);
      expect(c.selection.baseOffset, pain + 5, reason: 'the caret stays on that line');
    });

    for (final named in [0, 1]) {
      testWidgets('erasing a new empty item makes it a plain line, as the keyboard sends it ($named)', (tester) async {
        final (editor, pain) = await twoBullets(tester);
        final c = editor.controller;
        c.replaceText(pain + 4, 0, '\n', TextSelection.collapsed(offset: pain + 5));
        await settle(tester);
        // The line break before the caret, or (from Android's keyboard) the
        // empty line's own: the text is the same either way.
        c.replaceText(pain + 4 + named, 1, '', TextSelection.collapsed(offset: pain + 4));
        await settle(tester);
        expect(tail(tester, 3), [
          (NoteBlockType.bullet, 'Pain'),
          (NoteBlockType.text, ''),
          (NoteBlockType.bullet, 'Lait'),
        ]);
      });
    }

    testWidgets('selected lines turn into checkboxes, bullets, or text', (tester) async {
      final (editor, pain) = await twoBullets(tester);
      final c = editor.controller;
      c.updateSelection(TextSelection(baseOffset: pain + 1, extentOffset: pain + 7), ChangeSource.local);
      expect(editor.isList(NoteBlockType.bullet), isTrue);

      editor.toggleList(NoteBlockType.todo);
      await settle(tester);
      expect(tail(tester, 2), [(NoteBlockType.todo, 'Pain'), (NoteBlockType.todo, 'Lait')]);

      editor.toggleList(NoteBlockType.todo);
      await settle(tester);
      expect(tail(tester, 2), [(NoteBlockType.text, 'Pain'), (NoteBlockType.text, 'Lait')]);

      editor.toggleList(NoteBlockType.bullet);
      await settle(tester);
      expect(tail(tester, 2), [(NoteBlockType.bullet, 'Pain'), (NoteBlockType.bullet, 'Lait')]);
      expect(c.selection, TextSelection(baseOffset: pain + 1, extentOffset: pain + 7));
    });
  });

  testWidgets('Android back on the notes tab goes home instead of leaving', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.notes);
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(router.state.uri.path, Routes.home);
  });

  testWidgets('a long press on a card lets the cards be rearranged on home', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    List<String> order() =>
        pinnedInOrder(tester.element(find.byType(HomeScreen)).read<ListRepository>().lists).map((l) => l.name).toList();
    expect(order(), ['Courses', 'Maison', 'Dîner', 'Lisbonne']);

    // Courses, held down, then dropped where Lisbonne was: the others move up.
    final drag = await tester.startGesture(tester.getCenter(find.text('Courses.')));
    await tester.pump(const Duration(milliseconds: 600));
    await drag.moveTo(tester.getCenter(find.text('Lisbonne.')));
    await tester.pump();
    await drag.moveTo(tester.getCenter(find.text('Lisbonne.')) + const Offset(0, 1));
    await tester.pump();
    await drag.up();
    await settle(tester);
    expect(order(), ['Maison', 'Dîner', 'Lisbonne', 'Courses']);

    // Still arranging: a tap on a card stops, rather than opening it.
    await tester.tap(find.text('Maison.'));
    await settle(tester);
    expect(find.byType(ListScreen), findsNothing);
    await tester.tap(find.text('Maison.'));
    await settle(tester);
    expect(find.byType(ListScreen), findsOneWidget);
  });

  testWidgets('all lists, editing: pinned lists move by their dots or a long press', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.lists);
    await settle(tester);
    await tester.tap(find.text('Modifier'));
    await settle(tester);
    final repo = tester.element(find.byType(AllListsScreen)).read<ListRepository>();
    List<String> order() => pinnedInOrder(repo.lists).map((l) => l.name).toList();
    Future<void> dragFrom(Offset start, {Duration hold = Duration.zero}) async {
      final g = await tester.startGesture(start);
      await tester.pump(hold);
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle(tester);
    }

    // Near the dots, not right on them.
    await dragFrom(tester.getCenter(find.byType(Grip).first) + const Offset(-12, 14));
    expect(order(), ['Maison', 'Dîner', 'Lisbonne', 'Courses']);

    await dragFrom(tester.getCenter(find.text('Maison')), hold: const Duration(milliseconds: 600));
    expect(order(), ['Dîner', 'Lisbonne', 'Courses', 'Maison']);
  });

  testWidgets('checkboxes keep their size and stand by the first line', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final repo = tester.element(find.byType(HomeScreen)).read<ListRepository>();
    await repo.addTask('c', 'Une tâche assez longue pour tenir sur deux lignes au moins, voire trois', byId: 'me');
    await settle(tester);
    router.go(Routes.list('c'));
    await settle(tester);
    final long = find.ancestor(of: find.textContaining('Une tâche assez longue'), matching: find.byType(TaskRow));
    final check = find.descendant(of: long, matching: find.byType(PnCheck));
    expect(tester.getSize(check), const Size.square(PnCheck.size));
    expect(tester.getTopLeft(check).dy, tester.getTopLeft(long).dy + 4, reason: 'by the first line, not centered');

    router.go(Routes.note('ca'));
    await settle(tester);
    for (final c in tester.widgetList<PnCheck>(find.byType(PnCheck))) {
      expect(tester.getSize(find.byWidget(c)), const Size.square(PnCheck.size));
    }
  });

  testWidgets('the list tag of a task in Today is cut short, and opens its list', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final repo = tester.element(find.byType(HomeScreen)).read<ListRepository>();
    final courses = repo.lists.firstWhere((l) => l.id == 'c');
    await repo.updateList(courses.copyWith(name: 'Courses pour le grand repas de famille du dimanche'));
    await settle(tester);

    final tag = find.widgetWithText(InfoPill, 'Courses pour le grand repas de famille du dimanche').first;
    expect(tester.getSize(tag).width, lessThanOrEqualTo(120));
    expect(tester.getSize(tag).height, lessThan(30), reason: 'on one line');
    await tester.tap(tag);
    await settle(tester);
    expect(router.state.uri.path, Routes.list('c'));
  });

  testWidgets('a swipe on a task of Today goes to Notes, and deletes nothing', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final repo = tester.element(find.byType(HomeScreen)).read<ListRepository>();
    final before = repo.tasks.length;
    await tester.fling(find.text('Tomates'), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(router.state.uri.path, Routes.notes);
    expect(repo.tasks, hasLength(before));
  });

  testWidgets('the bottom bar shows on Lists and Notes only', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    bool barShown() => tester.getTopLeft(find.text('Listes')).dy < 844;
    expect(barShown(), isTrue);
    for (final route in [Routes.lists, Routes.settings, Routes.list('c')]) {
      router.go(route);
      await settle(tester);
      expect(barShown(), isFalse, reason: route);
    }
    router.go(Routes.notes);
    await settle(tester);
    expect(barShown(), isTrue);
  });

  testWidgets('a swipe sideways goes from Lists to Notes and back', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    // Mid-swipe, both pages follow the finger, side by side.
    final drag = await tester.startGesture(tester.getCenter(find.text('PICNOTE.')));
    await drag.moveBy(const Offset(-40, 0));
    await drag.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.text('PICNOTE.'), findsOneWidget, reason: 'one header, shared by both pages');
    expect(tester.getTopLeft(find.text('PICNOTE.')).dx, 20, reason: 'the header stays in place');
    expect(find.text('Notes.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Notes.')).dx, lessThan(390));
    // The blocks trail the title: Today, leaving, is further to the left.
    expect(tester.getTopLeft(find.text('Aujourd’hui.')).dx, lessThan(tester.getTopLeft(find.text('Salut Mel,')).dx));
    // The tabs follow the finger: Lists fading, Notes not yet selected.
    final lists = tester.widget<Text>(find.text('Listes')).style!.color!;
    expect(lists, isNot(PnColors.terraDark));
    expect(lists, isNot(PnColors.muted));
    // Let go before halfway: back to Lists.
    await drag.up();
    await settle(tester);
    expect(router.state.uri.path, Routes.home);
    expect(find.text('Notes.'), findsNothing);

    await tester.fling(find.text('PICNOTE.'), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(router.state.uri.path, Routes.notes);
    await tester.fling(find.text('PICNOTE.'), const Offset(300, 0), 1000);
    await settle(tester);
    expect(router.state.uri.path, Routes.home);
  });

  testWidgets('home full: pinning a list goes to all lists to make room, then back to the list', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.list('b'));
    await settle(tester);
    await tester.tap(labeled('Options de la liste'));
    await settle(tester);
    await tester.tap(find.text('Épinglée sur l’accueil'));
    await settle(tester);
    expect(find.byType(AllListsScreen), findsOneWidget);
    expect(find.text('OK'), findsOneWidget, reason: 'in edit mode');

    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(AllListsScreen), findsNothing);
    expect(find.byType(ListScreen), findsOneWidget);
  });

  testWidgets('Android back on home stays there', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    expect(await tester.binding.handlePopRoute(), isTrue, reason: 'handled: the app stays open');
    await settle(tester);
    expect(router.state.uri.path, Routes.home);
  });

  testWidgets('the caret has a handle to slide it along', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tapAt(tester.getTopLeft(find.byType(QuillEditor)) + const Offset(10, 10));
    await settle(tester);
    expect(find.byType(CaretHandle), findsOneWidget);
    final before = editor.controller.selection.baseOffset;

    await tester.drag(find.byType(CaretHandle), const Offset(120, 0));
    await settle(tester);
    expect(editor.controller.selection.isCollapsed, isTrue);
    expect(editor.controller.selection.baseOffset, greaterThan(before));
  });

  testWidgets('the housemate typing does not open the keyboard here', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final live = tester.element(find.byType(Scaffold).first).read<LiveRepository>() as LiveRepositoryLocal;
    router.go(Routes.note('mo'));
    await settle(tester);
    live.receiveNote(
      'mo',
      LiveNote(
        userId: HouseholdRepositoryLocal.partner.id,
        title: 'Papiers moto',
        blocks: const [NoteBlock(id: 'x', text: 'Carte grise')],
        cursor: 5,
      ),
    );
    await settle(tester);
    expect(find.textContaining('Carte grise', findRichText: true), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<QuillEditor>(), isNull);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('scrolled up to watch the housemate type, the page does not jump back to this user’s caret', (
    tester,
  ) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final live = tester.element(find.byType(Scaffold).first).read<LiveRepository>() as LiveRepositoryLocal;
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);
    // A long note, this user's caret at its end.
    final end = editor.controller.document.length - 1;
    final lines = List.filled(60, 'Ligne').join('\n');
    editor.controller.replaceText(end, 0, '\n$lines', TextSelection.collapsed(offset: end + 1 + lines.length));
    await settle(tester);
    final page = Scrollable.of(tester.element(find.byType(NoteEditor))).position;
    expect(page.pixels, greaterThan(0), reason: 'followed the caret down');

    page.jumpTo(0);
    await tester.pump();
    final saved = tester.element(find.byType(NoteEditor)).read<NoteRepository>().notes.firstWhere((n) => n.id == 'mo');
    for (final letter in ['A', 'AB', 'ABC']) {
      live.receiveNote(
        'mo',
        LiveNote(
          userId: HouseholdRepositoryLocal.partner.id,
          title: saved.title,
          blocks: [
            saved.blocks.first.copyWith(text: '$letter${saved.blocks.first.text}'),
            ...saved.blocks.skip(1),
          ],
          cursor: letter.length,
        ),
      );
      await settle(tester);
    }
    expect(editor.controller.document.toPlainText(), startsWith('ABC'));
    expect(page.pixels, 0);
    expect(editor.controller.selection.baseOffset, end + 1 + lines.length + 3, reason: 'still at its end');
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('undo takes back only this user’s own changes, not the housemate’s', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    final live = tester.element(find.byType(Scaffold).first).read<LiveRepository>() as LiveRepositoryLocal;
    router.go(Routes.note('mo'));
    await settle(tester);
    final editor = tester.state<NoteEditorState>(find.byType(NoteEditor));
    final notes = tester.element(find.byType(NoteEditor)).read<NoteRepository>();
    Note saved() => notes.notes.firstWhere((n) => n.id == 'mo');
    final first = saved().blocks.first.text;
    // They type "M" in front of the first line, on top of what they had
    // received of this user's changes.
    void fromHousemate() {
      final blocks = saved().blocks;
      live.receiveNote(
        'mo',
        LiveNote(
          userId: HouseholdRepositoryLocal.partner.id,
          title: saved().title,
          blocks: [
            blocks.first.copyWith(text: 'M${blocks.first.text}'),
            ...blocks.skip(1),
          ],
          cursor: 1,
        ),
      );
    }

    // Only the housemate typed: nothing to undo here.
    fromHousemate();
    await settle(tester);
    expect(editor.controller.document.toPlainText(), startsWith('M$first'));
    expect(editor.canUndo, isFalse);

    // This user types at the end, then the housemate types again.
    await tester.tap(find.byType(QuillEditor));
    await settle(tester);
    final end = editor.controller.document.length - 1;
    editor.controller.replaceText(end, 0, 'Y', TextSelection.collapsed(offset: end + 1));
    await tester.pump(const Duration(seconds: 1));
    fromHousemate();
    await settle(tester);
    expect(editor.controller.document.toPlainText().trimRight(), endsWith('Y'));
    expect(editor.controller.document.toPlainText(), startsWith('MM$first'));

    // Undo takes back the "Y", and leaves what the housemate typed.
    editor.undo();
    await settle(tester);
    final text = editor.controller.document.toPlainText();
    expect(text, startsWith('MM$first'));
    expect(text.trimRight().endsWith('Y'), isFalse);
    expect(editor.canUndo, isFalse);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a checkbox in a note checks its line', (tester) async {
    final router = await pumpApp(tester, const Size(390, 844));
    router.go(Routes.note('mo'));
    await settle(tester);

    await tester.tap(find.byType(PnCheck).first);
    await settle(tester);
    final blocks = tester
        .element(find.byType(NoteEditor))
        .read<NoteRepository>()
        .notes
        .firstWhere((n) => n.id == 'mo')
        .blocks;
    expect(blocks[1].done, isTrue);
    expect(blocks[2].done, isFalse);
  });

  testWidgets('on home, tapping a task checks it instead of editing it', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    final tomatoes = find.text('Tomates');
    await tester.ensureVisible(tomatoes);
    await settle(tester);

    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.tap(tomatoes);
    await settle(tester);
    expect(find.byType(TextField), findsNothing);
    final check = find.descendant(
      of: find.ancestor(of: tomatoes, matching: find.byType(Row)).first,
      matching: find.byType(PnCheck),
    );
    expect(tester.widget<PnCheck>(check).done, isTrue);
    // A short tick when checking…
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    // …and none when unchecking.
    await tester.tap(check);
    await settle(tester);
    expect(tester.widget<PnCheck>(check).done, isFalse);
    expect(haptics, hasLength(1));
  });
}
