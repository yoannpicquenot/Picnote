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
      );
      viewModel.setName('Mel');
      viewModel.setColor(sage);
    });

    tearDown(() => viewModel.dispose());

    Future<void> createUntilColor() async {
      viewModel.goTo(OnboardingStep.householdStart);
      viewModel.startCreating();
      viewModel.setHouseholdName('L’appart');
      viewModel.submitHouseholdName();
    }

    test('create: household name, then the color', () async {
      await createUntilColor();

      expect(viewModel.step, OnboardingStep.avatar);
      expect(households.household, isNull);
      expect(viewModel.back, OnboardingStep.create);
    });

    test('the color screen creates the household and goes home', () async {
      await createUntilColor();
      await viewModel.confirmAvatar();

      expect(viewModel.finished, isTrue);
      expect(households.household?.name, 'L’appart');
      expect(households.household?.members.single.color, sage);
      // Nobody invited yet: that happens from home.
      expect(households.household?.invite, isNull);
      expect(auth.user?.name, 'Mel');
      expect(auth.user?.color, sage);
    });

    test('back buttons follow the new order', () {
      final expected = {
        OnboardingStep.householdStart: OnboardingStep.name,
        OnboardingStep.create: OnboardingStep.householdStart,
        OnboardingStep.joinCode: OnboardingStep.householdStart,
        OnboardingStep.join: OnboardingStep.joinCode,
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
