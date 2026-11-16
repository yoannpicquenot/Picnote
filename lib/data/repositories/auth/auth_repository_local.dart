import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import 'auth_repository.dart';

/// In-memory fake for development. Any 6-digit code works, except:
/// 000000 is wrong, 111111 has expired, and 3 wrong codes lock sign-in.
class AuthRepositoryLocal extends AuthRepository {
  AuthRepositoryLocal({this._user});

  static const _maxAttempts = 3;

  User? _user;
  String? _email;
  int _wrongAttempts = 0;
  DateTime? _deletionDate;

  @override
  User? get user => _user;

  @override
  DateTime? get deletionDate => _deletionDate;

  @override
  Future<Result<void>> requestCode(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _email = email;
    _wrongAttempts = 0;
    return const Result.ok(null);
  }

  @override
  Future<Result<User>> verifyCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_wrongAttempts >= _maxAttempts) return Result.error(TooManyAttemptsException());
    if (code == '111111') return Result.error(ExpiredCodeException());
    if (code == '000000') {
      _wrongAttempts++;
      return Result.error(_wrongAttempts >= _maxAttempts ? TooManyAttemptsException() : WrongCodeException());
    }
    final user = User(id: 'me', email: _email ?? '');
    _user = user;
    _deletionDate = null;
    notifyListeners();
    return Result.ok(user);
  }

  @override
  Future<Result<User>> updateProfile({String? name, int? color}) async {
    final current = _user;
    if (current == null) return Result.error(Exception('Not signed in'));
    final user = current.copyWith(name: name, color: color);
    _user = user;
    notifyListeners();
    return Result.ok(user);
  }

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    _deletionDate = DateTime.now().add(const Duration(days: 15));
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> cancelDeletion() async {
    _deletionDate = null;
    notifyListeners();
    return const Result.ok(null);
  }
}
