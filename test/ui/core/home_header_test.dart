import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/activity/activity_repository_local.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/household.dart';
import 'package:picnote/l10n/app_localizations.dart';
import 'package:picnote/ui/core/ui/home_header.dart';
import 'package:picnote/ui/core/view_models/who_is_here.dart';

import '../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../testing/models/task_list.dart';

void main() {
  late int invites, joins;

  Future<void> pumpHeader(WidgetTester tester, Household household) async {
    invites = 0;
    joins = 0;
    final who = WhoIsHere(
      activityRepository: ActivityRepositoryLocal(),
      householdRepository: FakeHouseholdRepository(household: household),
      listRepository: FakeListRepository(),
      noteRepository: NoteRepositoryLocal(),
      meId: kMe.id,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeHeader(
            whoIsHere: who,
            onWordmark: () {},
            onInvite: () => invites++,
            onJoin: () => joins++,
            onSettings: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(RegExp('Foyer et réglages')));
    // The pending invitation's dots pulse forever: no pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('alone: "Invite someone" under this user, and "Join a household"', (tester) async {
    await pumpHeader(tester, kSolo);

    expect(find.text('Inviter quelqu’un'), findsOneWidget);
    expect(find.text('Rejoindre un foyer'), findsOneWidget);
    await tester.tap(find.text('Inviter quelqu’un'));
    expect(invites, 1);
  });

  testWidgets('invited by email: the address and "Invitation pending" in its place', (tester) async {
    const pending = Household(
      name: 'Maison',
      members: [kMe],
      invite: Invite(email: 'yoann@picnote.cc', code: 'K7H2M9'),
    );
    await pumpHeader(tester, pending);

    expect(find.text('yoann@picnote.cc'), findsOneWidget);
    expect(find.text('Invitation en attente'), findsOneWidget);
    expect(find.text('Inviter quelqu’un'), findsNothing);
    await tester.tap(find.text('yoann@picnote.cc'));
    expect(invites, 1);
  });

  testWidgets('a code given by hand is no invitation', (tester) async {
    const byCode = Household(
      name: 'Maison',
      members: [kMe],
      invite: Invite(email: '', code: 'K7H2M9'),
    );
    await pumpHeader(tester, byCode);

    expect(find.text('Inviter quelqu’un'), findsOneWidget);
    expect(find.text('Invitation en attente'), findsNothing);
  });

  testWidgets('two of us: the other member, no invite, no join', (tester) async {
    await pumpHeader(tester, kDuo);

    expect(find.text(kPartner.name), findsOneWidget);
    expect(find.text('Inviter quelqu’un'), findsNothing);
    expect(find.text('Rejoindre un foyer'), findsNothing);
  });

  testWidgets('the other opening the app: a ring around their avatar, twice, then still', (tester) async {
    final activity = ActivityRepositoryLocal();
    final who = WhoIsHere(
      activityRepository: activity,
      householdRepository: FakeHouseholdRepository(household: kDuo),
      listRepository: FakeListRepository(),
      noteRepository: NoteRepositoryLocal(),
      meId: kMe.id,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: activity,
            builder: (context, _) =>
                HomeHeader(whoIsHere: who, onWordmark: () {}, onInvite: () {}, onJoin: () {}, onSettings: () {}),
          ),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    final ring = find.byWidgetPredicate(
      (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border != null,
    );
    expect(ring, findsNothing);

    activity.setOnline(kPartner.id, true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(ring, findsOneWidget, reason: 'first wave');
    await tester.pump(const Duration(milliseconds: 900));
    expect(ring, findsOneWidget, reason: 'second wave');
    await tester.pump(const Duration(milliseconds: 600));
    expect(ring, findsNothing, reason: 'stops after two');
  });
}
