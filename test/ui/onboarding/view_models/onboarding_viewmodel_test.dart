import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/household/household_repository_local.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/domain/models/user.dart';
import 'package:picnote/ui/onboarding/view_models/onboarding_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('OnboardingViewModel', () {
    const terra = 0xFFAF5C3C, sage = 0xFF3F7063;
    late FakeAuthRepository auth;
    late FakeHouseholdRepository households;
    late FakeListRepository lists;
    late OnboardingViewModel viewModel;

    setUp(() {
      auth = FakeAuthRepository(
        user: const User(id: 'me', email: 'mel@picnote.cc'),
      );
      households = FakeHouseholdRepository();
      lists = FakeListRepository(lists: [kSharedList]);
      viewModel = OnboardingViewModel(
        authRepository: auth,
        householdRepository: households,
        listRepository: lists,
        noteRepository: NoteRepositoryLocal(),
        sentAnimation: Duration.zero,
      );
      viewModel.setName('Mel');
      viewModel.setColor(sage);
    });

    tearDown(() => viewModel.dispose());

    Future<void> createUntilColor({required bool solo}) async {
      viewModel.goTo(OnboardingStep.householdStart);
      viewModel.goTo(OnboardingStep.household);
      viewModel.choose(solo: solo);
      viewModel.setHouseholdName('L’appart');
      viewModel.submitHouseholdName();
    }

    test('the color comes after the household name', () async {
      await createUntilColor(solo: true);

      expect(viewModel.step, OnboardingStep.avatar);
      expect(households.household, isNull);
      expect(viewModel.back, OnboardingStep.create);
    });

    test('"Just me" creates the household from the color screen and finishes', () async {
      await createUntilColor(solo: true);
      await viewModel.confirmAvatar();

      expect(viewModel.finished, isTrue);
      expect(households.household?.name, 'L’appart');
      expect(households.household?.members.single.color, sage);
      expect(auth.user?.name, 'Mel');
      expect(auth.user?.color, sage);
    });

    test('"The two of us" goes on to how to invite, by email', () async {
      await createUntilColor(solo: false);
      await viewModel.confirmAvatar();

      expect(viewModel.finished, isFalse);
      expect(viewModel.step, OnboardingStep.inviteHow);

      viewModel.inviteByEmail();
      expect(viewModel.back, OnboardingStep.inviteHow);
      await viewModel.sendInvite('yoann@picnote.cc');
      expect(viewModel.sentTo, 'yoann@picnote.cc');
      expect(households.household?.invite?.email, 'yoann@picnote.cc');

      // "Invitation sent." for a moment, then home.
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.finished, isTrue);
    });

    test('inviting by code shows a code without sending an email', () async {
      await createUntilColor(solo: false);
      await viewModel.confirmAvatar();
      await viewModel.inviteByCode();

      expect(viewModel.step, OnboardingStep.inviteCode);
      expect(viewModel.inviteCode, HouseholdRepositoryLocal.demoCode);
      expect(households.household?.invite?.byCode, isTrue);
    });

    test('going back to the color after inviting updates the household', () async {
      await createUntilColor(solo: false);
      await viewModel.confirmAvatar();
      viewModel.goBack();
      expect(viewModel.step, OnboardingStep.avatar);

      viewModel.setColor(terra);
      await viewModel.confirmAvatar();
      expect(households.household?.members.single.color, terra);
      expect(viewModel.step, OnboardingStep.inviteHow);
    });

    test('back buttons follow the new order', () {
      final expected = {
        OnboardingStep.householdStart: OnboardingStep.name,
        OnboardingStep.household: OnboardingStep.householdStart,
        OnboardingStep.joinCode: OnboardingStep.householdStart,
        OnboardingStep.inviteHow: OnboardingStep.avatar,
        OnboardingStep.inviteCode: OnboardingStep.inviteHow,
      };
      for (final MapEntry(key: step, value: back) in expected.entries) {
        viewModel.goTo(step);
        expect(viewModel.back, back, reason: '$step');
      }
    });

    test('the household intro plays once', () {
      expect(viewModel.householdIntroPlayed, isFalse);
      viewModel.householdIntroDone();
      expect(viewModel.householdIntroPlayed, isTrue);
    });

    test('rejects an unknown invite code', () async {
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode('K7H2N9');

      expect(viewModel.joinState, JoinCodeState.error);
      expect(viewModel.step, OnboardingStep.joinCode);
    });

    test('keeps a color the host does not wear', () async {
      viewModel.setColor(terra); // Yoann is sage
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode(HouseholdRepositoryLocal.demoCode);
      viewModel.previewJoin();

      expect(viewModel.color, terra);
      expect(viewModel.takenColors, {sage});
    });

    test('joins after picking a color the host does not wear', () async {
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode(HouseholdRepositoryLocal.demoCode);
      expect(viewModel.step, OnboardingStep.join);

      viewModel.previewJoin();
      expect(viewModel.step, OnboardingStep.avatar);
      expect(viewModel.back, OnboardingStep.join);
      // Yoann is sage already: another one is picked, and sage can't be.
      expect(viewModel.color, isNot(sage));
      viewModel.setColor(sage);
      expect(viewModel.color, isNot(sage));

      await viewModel.confirmAvatar();
      expect(viewModel.finished, isTrue);
      expect(households.household?.members.map((m) => m.name), ['Yoann', 'Mel']);
      // Existing lists come along as personal.
      expect(lists.lists.single.isShared, isFalse);
    });
  });
}
