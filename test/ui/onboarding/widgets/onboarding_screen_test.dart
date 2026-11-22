import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/user.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/core/ui/buttons.dart';
import 'package:picnote/ui/onboarding/view_models/onboarding_viewmodel.dart';
import 'package:picnote/ui/onboarding/widgets/household_start.dart';
import 'package:picnote/ui/onboarding/widgets/onboarding_screen.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';

void main() {
  late OnboardingViewModel viewModel;
  late FakeHouseholdRepository households;
  late bool finished;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    households = FakeHouseholdRepository();
    viewModel = OnboardingViewModel(
      authRepository: FakeAuthRepository(
        user: const User(id: 'me', email: 'mel@picnote.cc'),
      ),
      householdRepository: households,
      listRepository: FakeListRepository(),
      noteRepository: NoteRepositoryLocal(),
    );
    addTearDown(viewModel.dispose);
    viewModel.setName('Mel');
    finished = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(viewModel: viewModel, onFinished: () => finished = true),
      ),
    );
  }

  BackSquare backButton(WidgetTester tester) =>
      tester.widget<BackSquare>(find.descendant(of: find.byType(HouseholdStart), matching: find.byType(BackSquare)));

  testWidgets('the household intro plays once, then the choices lead on', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ton foyer.'), findsOneWidget);
    // Back is disabled and the choices hidden while the bar fills.
    expect(backButton(tester).onPressed, isNull);
    expect(find.text('Créer un foyer').hitTestable(), findsNothing);

    await tester.pump(HouseholdStart.introLength);
    await tester.pump(const Duration(seconds: 2));
    expect(backButton(tester).onPressed, isNotNull);
    expect(viewModel.householdIntroPlayed, isTrue);

    // Back on 06 from the household name: everything is there at once.
    await tester.tap(find.text('Créer un foyer'));
    await tester.pumpAndSettle();
    expect(find.text('Nomme ton foyer.'), findsOneWidget);
    expect(find.text('Tu pourras le changer plus tard.'), findsOneWidget);
    await tester.tap(find.byType(BackSquare));
    await tester.pumpAndSettle();
    expect(backButton(tester).onPressed, isNotNull);
    expect(find.text('Rejoindre un foyer').hitTestable(), findsOneWidget);
  });

  testWidgets('create: name, color, then home, with no invitation step', (tester) async {
    await pump(tester);
    viewModel.householdIntroDone();
    viewModel.goTo(OnboardingStep.householdStart);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un foyer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'L’appart');
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Choisis ta couleur.'), findsOneWidget);
    await tester.tap(find.text('Aller dans mon foyer'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(households.household?.name, 'L’appart');
  });
}
