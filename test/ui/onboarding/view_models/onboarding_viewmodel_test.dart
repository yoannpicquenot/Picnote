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
      viewModel.setColor(0xFF3F7063);
    });

    tearDown(() => viewModel.dispose());

    test('"Just me" creates the household and finishes', () async {
      viewModel.choose(solo: true);
      viewModel.setHouseholdName('L’appart');
      await viewModel.createHousehold();

      expect(viewModel.finished, isTrue);
      expect(households.household?.name, 'L’appart');
      expect(households.household?.members.single.name, 'Mel');
      expect(auth.user?.name, 'Mel');
      expect(auth.user?.color, 0xFF3F7063);
    });

    test('"The two of us" goes on to the invitation', () async {
      viewModel.choose(solo: false);
      viewModel.setHouseholdName('L’appart');
      await viewModel.createHousehold();

      expect(viewModel.finished, isFalse);
      expect(viewModel.step, OnboardingStep.invite);

      await viewModel.sendInvite('yoann@picnote.cc');
      expect(viewModel.invite?.email, 'yoann@picnote.cc');
    });

    test('rejects an unknown invite code', () async {
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode('K7H2N9');

      expect(viewModel.joinState, JoinCodeState.error);
      expect(viewModel.step, OnboardingStep.joinCode);
    });

    test('only says the color was taken when it was', () async {
      viewModel.setColor(0xFFAF5C3C); // terracotta; Yoann is sage
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode(HouseholdRepositoryLocal.demoCode);
      expect(viewModel.colorWasTaken, isFalse);
      expect(viewModel.color, 0xFFAF5C3C);

      viewModel.setColor(0xFF3F7063);
      viewModel.goTo(OnboardingStep.join);
      expect(viewModel.colorWasTaken, isTrue);
    });

    test('joins with a valid code, picking a color the host does not wear', () async {
      viewModel.goTo(OnboardingStep.joinCode);
      await viewModel.setJoinCode(HouseholdRepositoryLocal.demoCode);

      expect(viewModel.step, OnboardingStep.join);
      // Yoann is sage already.
      expect(viewModel.color, isNot(0xFF3F7063));

      await viewModel.join();
      expect(viewModel.finished, isTrue);
      expect(households.household?.members.map((m) => m.name), ['Yoann', 'Mel']);
      // Existing lists come along as personal.
      expect(lists.lists.single.isShared, isFalse);
    });
  });
}
