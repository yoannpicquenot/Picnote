import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/choice_card.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/invite_code_boxes.dart';
import '../../core/ui/invite_form.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/rise_in.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../view_models/invite_viewmodel.dart';
import 'invite_sent.dart';

/// The invite panel, the same from home, the avatars' menu, the settings, a
/// list or a note. It opens on the pending invitation when there is one,
/// otherwise on the choice between email and code.
Future<void> showInviteSheet(BuildContext context) {
  final viewModel = InviteViewModel(householdRepository: context.read());
  return showPnSheet<void>(context, InviteSheet(viewModel: viewModel), editing: true).whenComplete(viewModel.dispose);
}

class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.viewModel});

  final InviteViewModel viewModel;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  final _shareKey = GlobalKey();

  /// "Code copied" for 2 s on the share button, when there is no share sheet.
  bool _copied = false;

  InviteViewModel get _vm => widget.viewModel;

  /// Made once: a new one each build would subscribe again while the sheet
  /// closes, after the view model is gone.
  late final _changes = Listenable.merge([_vm, _vm.send, _vm.cancel, _vm.createCode]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) => switch (_vm.step) {
        InviteStep.choose => PnSheet(title: l10n.inviteTheOther, children: _choose(l10n)),
        InviteStep.email => PnSheet(title: l10n.inviteTheOther, children: _email(l10n)),
        InviteStep.code => PnSheet(title: l10n.inviteCodeTitle, children: _code(l10n)),
      },
    );
  }

  Widget _backAnd(AppLocalizations l10n, Widget button) => Row(
    children: [
      BackSquare(label: l10n.back, onPressed: () => _vm.goTo(InviteStep.choose)),
      const SizedBox(width: 8),
      Expanded(child: button),
    ],
  );

  List<Widget> _choose(AppLocalizations l10n) => [
    Text(l10n.inviteHowSub, style: PnText.sub),
    ChoiceRow(
      ChoiceCard(visual: const IconDisc(PnIcons.mail), title: l10n.byEmail, onTap: () => _vm.goTo(InviteStep.email)),
      ChoiceCard(
        visual: const IconDisc(PnIcons.code, size: 24),
        title: l10n.byCode,
        onTap: () => _vm.goTo(InviteStep.code),
      ),
    ),
  ];

  List<Widget> _email(AppLocalizations l10n) {
    final sentTo = _vm.sentTo;
    if (sentTo != null) {
      return [
        InviteSent(title: l10n.invitationSent, to: l10n.invitationSentTo(sentTo), email: sentTo),
        RiseIn(
          delay: const Duration(milliseconds: 1300),
          child: PnButton(label: l10n.closeLabel, onPressed: () => Navigator.pop(context)),
        ),
      ];
    }
    final pending = _vm.pending;
    if (pending != null) {
      return [
        InviteRow(
          invite: pending,
          onResend: () {
            _vm.resend.execute();
            showTopToast(context, l10n.invitationResent);
          },
          onCancel: _vm.cancel.execute,
        ),
        CodeCard(code: pending.code, onCopied: () => showTopToast(context, l10n.codeCopied)),
      ];
    }
    return [
      Text(l10n.inviteSub(_vm.householdName), style: PnText.sub),
      if (_vm.send.error) Notice(text: l10n.offlineTryAgain),
      InviteEmailForm(
        // After "Cancel", the address comes back in the field.
        key: ValueKey(_vm.cancelledEmail),
        initialEmail: _vm.cancelledEmail,
        onSend: (email) {
          FocusScope.of(context).unfocus();
          _vm.send.execute(email);
        },
        sendButton: (send) =>
            _backAnd(l10n, PnButton(label: l10n.sendInvitation, onPressed: _vm.send.running ? null : send)),
      ),
    ];
  }

  List<Widget> _code(AppLocalizations l10n) {
    final code = _vm.code;
    return [
      Text(l10n.inviteCodeSub, style: PnText.sub),
      InviteCodeBoxes(code: code, label: l10n.inviteCodeGroupLabel(code?.split('').join(' ') ?? '')),
      if (_vm.createCode.error) Notice(text: l10n.offlineTryAgain),
      _backAnd(
        l10n,
        Semantics(
          liveRegion: true,
          child: PnButton(
            key: _shareKey,
            label: _copied ? l10n.codeCopied : l10n.shareCode,
            icon: _copied ? PnIcons.check : PnIcons.share,
            onPressed: code == null ? null : () => _share(code),
          ),
        ),
      ),
    ];
  }

  /// Opens the device's share sheet. Closing it without choosing does
  /// nothing; without a share sheet, the code is copied instead.
  Future<void> _share(String code) async {
    final l10n = AppLocalizations.of(context);
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.shareCodeText(code),
          // Where the sheet points from on iPad.
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      setState(() => _copied = true);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _copied = false);
    }
  }
}
