import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/ui/auth/view_models/auth_viewmodel.dart';

import '../../../../testing/fakes/repositories/fake_auth_repository.dart';

void main() {
  group('AuthViewModel', () {
    late FakeAuthRepository auth;
    late AuthViewModel viewModel;

    setUp(() {
      auth = FakeAuthRepository(user: null);
      viewModel = AuthViewModel(authRepository: auth);
    });

    tearDown(() => viewModel.dispose());

    Future<void> enterEmail() async {
      viewModel.goTo(AuthStep.email);
      viewModel.setEmail('mel@picnote.cc');
      await viewModel.submitEmail();
    }

    Future<void> enterCode(String code) async {
      viewModel.setCode(code);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    test('refuses an address that does not look like one', () async {
      viewModel.goTo(AuthStep.email);
      viewModel.setEmail('mel@picnote');
      await viewModel.submitEmail();

      expect(viewModel.emailInvalid, isTrue);
      expect(viewModel.step, AuthStep.email);
    });

    test('sends a code and waits before allowing a resend', () async {
      await enterEmail();

      expect(viewModel.step, AuthStep.code);
      expect(viewModel.resendIn, 30);
    });

    test('signs in as soon as the 6th digit is typed', () async {
      await enterEmail();
      await enterCode('482913');

      expect(viewModel.codeError, isNull);
      expect(auth.user?.email, 'mel@picnote.cc');
    });

    test('flags a wrong code, cleared by typing again', () async {
      await enterEmail();
      await enterCode('000000');
      expect(viewModel.codeError, CodeError.wrong);
      expect(auth.user, isNull);

      viewModel.setCode('4');
      expect(viewModel.codeError, isNull);
    });

    test('flags an expired code', () async {
      await enterEmail();
      await enterCode('111111');

      expect(viewModel.codeError, CodeError.expired);
    });

    test('locks after too many wrong codes', () async {
      await enterEmail();
      for (var i = 0; i < 3; i++) {
        await enterCode('000000');
      }

      expect(viewModel.codeError, CodeError.locked);
      viewModel.setCode('1');
      expect(viewModel.code, '000000');
    });
  });
}
