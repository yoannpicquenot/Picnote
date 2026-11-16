import 'package:picnote/data/repositories/household/household_repository_local.dart';

/// Household fake where nobody joins on their own unless asked.
class FakeHouseholdRepository extends HouseholdRepositoryLocal {
  FakeHouseholdRepository({super.household, super.partnerJoinsAfter = null});
}
