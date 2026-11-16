import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/activity/activity_repository_local.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/household.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/home/view_models/home_viewmodel.dart';
import 'package:picnote/ui/home/widgets/home_screen.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  late FakeListRepository repository;

  setUp(() {
    repository = FakeListRepository(lists: [kSharedList, kPersonalList], tasks: kSharedTasks);
  });

  Future<void> pumpHome(WidgetTester tester, {Household household = kDuo}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Scaffold(
          body: HomeScreen(
            viewModel: HomeViewModel(
              listRepository: repository,
              authRepository: FakeAuthRepository(),
              householdRepository: FakeHouseholdRepository(household: household),
              noteRepository: NoteRepositoryLocal(),
              activityRepository: ActivityRepositoryLocal(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows list cards with what is left', (tester) async {
    await pumpHome(tester);

    expect(find.text('PICNOTE.'), findsOneWidget);
    expect(find.text('Salut Mel,'), findsOneWidget);
    expect(find.text('Courses.'), findsOneWidget);
    expect(find.text('3 restants'), findsOneWidget);
    expect(find.text('Cadeaux.'), findsOneWidget);
    expect(find.text('Vide'), findsOneWidget);
    expect(find.text('Perso'), findsOneWidget);
  });

  testWidgets('hides the personal mark when alone in the household', (tester) async {
    await pumpHome(tester, household: kSolo);

    expect(find.text('Cadeaux.'), findsOneWidget);
    expect(find.text('Perso'), findsNothing);
  });

  testWidgets('says nothing is planned today', (tester) async {
    await pumpHome(tester);

    expect(find.text('Aujourd’hui.'), findsOneWidget);
    expect(find.text('Rien de prévu. Profites-en.'), findsOneWidget);
  });

  testWidgets('invites to create the first list', (tester) async {
    repository = FakeListRepository();
    await pumpHome(tester);

    expect(find.text('Ta première liste.'), findsOneWidget);
    expect(find.text('On commence ?'), findsOneWidget);
  });

  testWidgets('retries after a load error', (tester) async {
    repository = FakeListRepository(failing: true);
    await pumpHome(tester);

    expect(find.text('Impossible de charger tes listes'), findsOneWidget);

    repository.failing = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Ta première liste.'), findsOneWidget);
  });

  testWidgets('keeps showing lists already loaded when a refresh fails', (tester) async {
    repository.failing = true;
    await pumpHome(tester);

    expect(find.text('Courses.'), findsOneWidget);
    expect(find.text('Impossible de charger tes listes'), findsNothing);
  });
}
