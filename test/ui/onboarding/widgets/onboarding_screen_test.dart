import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/household/household_repository_local.dart';
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
  String? clipboard;

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
    // No share sheet in tests: sharing falls back to the clipboard.
    clipboard = null;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
      return null;
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async => throw PlatformException(code: 'unavailable'),
    );
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

    // Back on 06 from 06c: everything is there at once.
    await tester.tap(find.text('Créer un foyer'));
    await tester.pumpAndSettle();
    expect(find.text('C’est pour qui ?'), findsOneWidget);
    await tester.tap(find.byType(BackSquare));
    await tester.pumpAndSettle();
    expect(backButton(tester).onPressed, isNotNull);
    expect(find.text('Rejoindre un foyer').hitTestable(), findsOneWidget);
  });

  Future<void> reachInviteHow(WidgetTester tester) async {
    viewModel.householdIntroDone();
    viewModel.goTo(OnboardingStep.household);
    await tester.pumpAndSettle();
    await tester.tap(find.text('À deux'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'L’appart');
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Choisis ta couleur.'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Comment l’inviter ?'), findsOneWidget);
  }

  testWidgets('by code: the code, shared or copied when there is no share sheet', (tester) async {
    await pump(tester);
    await reachInviteHow(tester);

    await tester.tap(find.text('Par code'));
    await tester.pumpAndSettle();
    expect(find.text('Donne-lui ce code.'), findsOneWidget);
    for (final ch in HouseholdRepositoryLocal.demoCode.split('')) {
      expect(find.text(ch), findsWidgets);
    }

    await tester.tap(find.text('Partager le code'));
    await tester.pumpAndSettle();
    expect(clipboard, HouseholdRepositoryLocal.demoCode);
    expect(find.text('Code copié'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Partager le code'), findsOneWidget);

    await tester.tap(find.text('Voir mes listes'));
    expect(finished, isTrue);
  });

  testWidgets('by email: "Invitation sent." then home', (tester) async {
    await pump(tester);
    await reachInviteHow(tester);

    await tester.tap(find.text('Par e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Invite ta moitié.'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'yoann@picnote.cc');
    await tester.pump();
    await tester.tap(find.text('Envoyer l’invitation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Invitation envoyée.'), findsOneWidget);
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(finished, isTrue);
  });
}
