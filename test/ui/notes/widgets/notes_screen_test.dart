import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/notes/view_models/notes_viewmodel.dart';
import 'package:picnote/ui/notes/widgets/notes_screen.dart';

import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  testWidgets('no note yet: "Your first note." opens a new note', (tester) async {
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotesScreen(
            viewModel: NotesViewModel(
              noteRepository: NoteRepositoryLocal(),
              householdRepository: FakeHouseholdRepository(household: kDuo),
            ),
            onCreateNote: () => created++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ta première note.'), findsOneWidget);
    expect(find.text('Une idée, une recette, le code wifi : garde-le ici.'), findsOneWidget);
    await tester.tap(find.text('Créer une note'));
    expect(created, 1);
  });
}
