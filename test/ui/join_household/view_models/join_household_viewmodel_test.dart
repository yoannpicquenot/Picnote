import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/data/repositories/household/household_repository_local.dart';
import 'package:picnote/data/repositories/note/note_repository_local.dart';
import 'package:picnote/ui/join_household/view_models/join_household_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';
import '../../../../testing/fakes/repositories/fake_household_repository.dart';
import '../../../../testing/fakes/repositories/fake_list_repository.dart';
import '../../../../testing/models/task_list.dart';

void main() {
  group('JoinHouseholdViewModel', () {
    late FakeHouseholdRepository households;
    late FakeListRepository lists;
    late JoinHouseholdViewModel viewModel;

    setUp(() {
      households = FakeHouseholdRepository(household: kSolo);
      lists = FakeListRepository(lists: [kSharedList]);
      viewModel = JoinHouseholdViewModel(
        authRepository: FakeAuthRepository(),
        householdRepository: households,
        listRepository: lists,
        noteRepository: NoteRepositoryLocal(),
      );
    });

    test('a wrong code: invalid, and nothing moves', () async {
      await viewModel.setCode('K7H2N9');

      expect(viewModel.state, JoinHouseholdState.invalid);
      expect(households.household?.name, kSolo.name);
    });

    test('waits for the 6th character', () async {
      await viewModel.setCode('K7H2');
      expect(viewModel.state, JoinHouseholdState.idle);
    });

    test('joins, the lists coming along as personal', () async {
      await viewModel.setCode(HouseholdRepositoryLocal.demoCode);

      expect(viewModel.state, JoinHouseholdState.joined);
      expect(viewModel.householdName, 'Maison Saint-Rambert');
      expect(households.household?.members.map((m) => m.id), [HouseholdRepositoryLocal.partner.id, kMe.id]);
      expect(lists.lists.single.isShared, isFalse);
    });
  });
}
