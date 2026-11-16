import 'package:picnote/data/repositories/auth/auth_repository_local.dart';

import '../../models/task_list.dart';

/// Signed in as [kMe] unless told otherwise. Same code rules as the local
/// repository: 000000 is wrong, 111111 has expired.
class FakeAuthRepository extends AuthRepositoryLocal {
  FakeAuthRepository({super.user = kMeUser});
}
