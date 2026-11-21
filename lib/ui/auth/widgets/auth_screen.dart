import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/auth_shell.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/mascot.dart';
import '../../core/ui/pn_icon.dart';
import '../view_models/auth_viewmodel.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => switch (viewModel.step) {
        AuthStep.welcome => _Welcome(viewModel),
        AuthStep.email => _Email(viewModel),
        AuthStep.code => _Code(viewModel),
      },
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome(this.vm);

  final AuthViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthShell(
      mood: MascotMood.happy,
      stepKey: AuthStep.welcome,
      children: [
        StepHeader(l10n.welcomeTitle, sub: Text(l10n.welcomeSub)),
        PnButton(label: l10n.continueWithEmail, icon: PnIcons.mail, onPressed: () => vm.goTo(AuthStep.email)),
      ],
    );
  }
}

class _Email extends StatefulWidget {
  const _Email(this.vm);

  final AuthViewModel vm;

  @override
  State<_Email> createState() => _EmailState();
}

class _EmailState extends State<_Email> {
  late final _controller = TextEditingController(text: widget.vm.email);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = widget.vm;
    return AuthShell(
      mood: vm.emailInvalid || vm.offline ? MascotMood.surprised : MascotMood.wink,
      stepKey: AuthStep.email,
      children: [
        StepHeader(l10n.emailTitle, sub: Text(l10n.emailSub)),
        PnTextField(
          controller: _controller,
          hint: l10n.emailHint,
          tall: true,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          error: vm.emailInvalid ? l10n.invalidEmail : null,
          onChanged: vm.setEmail,
          onSubmitted: (_) => vm.submitEmail(),
        ),
        if (vm.offline) Notice(text: l10n.offlineTryAgain),
        Row(
          children: [
            BackSquare(label: l10n.back, onPressed: () => vm.goTo(AuthStep.welcome)),
            const SizedBox(width: 8),
            Expanded(
              child: PnButton(label: l10n.continueLabel, onPressed: vm.sending ? null : vm.submitEmail),
            ),
          ],
        ),
      ],
    );
  }
}

class _Code extends StatelessWidget {
  const _Code(this.vm);

  final AuthViewModel vm;

  static bool _usesGmail(String email) =>
      RegExp(r'@(gmail|googlemail)\.com$', caseSensitive: false).hasMatch(email.trim());

  /// Gmail already searching for Picnote emails. On a phone, the Gmail app
  /// opens instead when it is installed.
  static Future<void> _openGmail() =>
      launchUrl(Uri.parse('https://mail.google.com/mail/u/0/#search/picnote'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = vm.codeError;
    const errorStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: PnColors.terraDark);
    final canResend = vm.resendIn <= 0 && error != CodeError.locked;
    return AuthShell(
      mood: error != null ? MascotMood.surprised : MascotMood.peek,
      stepKey: AuthStep.code,
      children: [
        StepHeader(
          l10n.codeTitle,
          sub: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l10n.codeSentTo),
                TextSpan(
                  text: vm.email.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: PnColors.ink),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        CodeBoxes(
          value: vm.code,
          label: l10n.codeFieldLabel,
          onChanged: vm.setCode,
          state: switch (error) {
            CodeError.locked => CodeBoxesState.locked,
            null => vm.checking ? CodeBoxesState.loading : CodeBoxesState.idle,
            _ => CodeBoxesState.error,
          },
        ),
        if (_usesGmail(vm.email) && error != CodeError.locked)
          PnButton(
            label: l10n.openGmail,
            icon: PnIcons.mail,
            background: PnColors.peach,
            foreground: PnColors.terraDark,
            onPressed: _openGmail,
          ),
        if (error == CodeError.wrong) Text(l10n.codeWrong, style: errorStyle),
        if (error == CodeError.expired) ...[
          Text(l10n.codeExpired, style: errorStyle),
          PnButton(label: l10n.getNewCode, onPressed: vm.resendCode),
        ],
        if (error == CodeError.locked) Notice(text: l10n.codeLocked),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LinkButton(label: l10n.changeEmail, onPressed: () => vm.goTo(AuthStep.email)),
            if (error != CodeError.expired)
              LinkButton(
                label: vm.resendIn > 0 && error != CodeError.locked ? l10n.resendIn(vm.resendIn) : l10n.resendCode,
                onPressed: canResend ? vm.resendCode : null,
              ),
          ],
        ),
        if (error == null) Text(l10n.checkSpam, style: PnText.sub),
      ],
    );
  }
}
