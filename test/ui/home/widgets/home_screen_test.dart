import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/household/household_repository.dart';
import 'package:picnote/data/repositories/household/household_repository_local.dart';
import 'package:picnote/data/repositories/invite_prompt/invite_prompt_repository.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/household.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/core/themes/theme.dart';
import 'package:picnote/ui/home/view_models/home_viewmodel.dart';
import 'package:picnote/ui/home/widgets/home_screen.dart';
import 'package:picnote/ui/invite/widgets/invite_sheet.dart';
import 'package:provider/provider.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  late FakeListRepository repository;
  late InvitePromptRepositoryLocal invitePrompt;

  setUp(() {
    invitePrompt = InvitePromptRepositoryLocal();
    repository = FakeListRepository(lists: [kSharedList, kPersonalList], tasks: kSharedTasks);
  });

  Future<void> pumpHome(WidgetTester tester, {Household household = kDuo}) async {
    final households = FakeHouseholdRepository(household: household);
    await tester.pumpWidget(
      // The invite sheets read the household from the tree.
      ChangeNotifierProvider<HouseholdRepository>.value(
        value: households,
        child: MaterialApp(
          // The toasts float, as in the app.
          theme: AppTheme.light,
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
                householdRepository: households,
                noteRepository: NoteRepositoryLocal(),
                invitePromptRepository: invitePrompt,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows list cards with what is left', (tester) async {
    await pumpHome(tester);

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
    // Nothing could be planned yet.
    expect(find.text('Aujourd’hui.'), findsNothing);
    expect(find.text('Demain.'), findsNothing);
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

  group('invite card', () {
    testWidgets('shows while alone, above the first list, and "Later" puts it away', (tester) async {
      repository = FakeListRepository();
      await pumpHome(tester, household: kSolo);

      expect(find.text('Invite ta moitié.'), findsOneWidget);
      final card = tester.getTopLeft(find.text('Invite ta moitié.')).dy;
      expect(card, lessThan(tester.getTopLeft(find.text('Ta première liste.')).dy));

      await tester.tap(find.bySemanticsLabel('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('Invite ta moitié.'), findsNothing);
      expect(invitePrompt.dismissed, isTrue);
    });

    testWidgets('not with a partner', (tester) async {
      await pumpHome(tester);
      expect(find.text('Invite ta moitié.'), findsNothing);
    });

    testWidgets('"Invite" opens the panel on the choice; by email, sent, then pending on home', (tester) async {
      await pumpHome(tester, household: kSolo);
      await tester.tap(find.text('Inviter'));
      await tester.pumpAndSettle();

      // The choice has no subtitle: the two cards come right under the title.
      expect(find.text('Par code'), findsOneWidget);
      await tester.tap(find.text('Par e-mail'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'yoann@picnote.cc');
      await tester.pump();
      await tester.tap(find.text('Envoyer l’invitation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Invitation envoyée.'), findsOneWidget);

      // "Close" comes after the animation, and the panel stays open until then.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Invitation envoyée.'), findsNothing);

      // On home: the pending invitation instead of the card.
      expect(find.text('yoann@picnote.cc'), findsOneWidget);
      expect(find.text('Inviter'), findsNothing);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Invitation annulée'), findsOneWidget);
      expect(find.text('Inviter'), findsOneWidget);
    });

    testWidgets('by code: the code in the panel, and the card stays', (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String;
        return null;
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async => throw PlatformException(code: 'unavailable'),
      );
      await pumpHome(tester, household: kSolo);
      await tester.tap(find.text('Inviter'));
      await tester.pumpAndSettle();
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

      // Back to the choice.
      await tester.tap(find.bySemanticsLabel('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Par e-mail'), findsOneWidget);

      // A code given by hand is no invitation: the card stays.
      Navigator.of(tester.element(find.text('Par e-mail'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Inviter'), findsOneWidget);
    });

    testWidgets('reopened while pending: the invitation, then the code in its own card', (tester) async {
      const pending = Household(
        name: 'Maison',
        members: [kMe],
        invite: Invite(email: 'yoann@picnote.cc', code: 'K7H2M9'),
      );
      await pumpHome(tester, household: pending);
      await tester.tap(find.text('yoann@picnote.cc'));
      await tester.pumpAndSettle();
      expect(find.text('Code à partager'), findsNothing);

      final vmContext = tester.element(find.byType(HomeScreen));
      showInviteSheet(vmContext);
      await tester.pumpAndSettle();
      expect(find.text('Code à partager'), findsOneWidget);
      expect(find.text('K7H2M9'), findsOneWidget);
      expect(find.text('Renvoyer'), findsNWidgets(2));
    });
  });
}
