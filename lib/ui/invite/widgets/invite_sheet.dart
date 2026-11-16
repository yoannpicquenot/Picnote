import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/invite_form.dart';
import '../../core/ui/sheet.dart';
import '../view_models/invite_viewmodel.dart';

/// "Invite someone." sheet, the in-app version of onboarding step 08.
Future<void> showInviteSheet(BuildContext context) {
  final viewModel = InviteViewModel(householdRepository: context.read());
  return showPnSheet<void>(context, InviteSheet(viewModel: viewModel), editing: true).whenComplete(viewModel.dispose);
}

class InviteSheet extends StatelessWidget {
  const InviteSheet({super.key, required this.viewModel});

  final InviteViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final invite = viewModel.invite;
        return PnSheet(
          title: l10n.inviteSomeoneTitle,
          children: [
            Text(
              invite != null ? l10n.inviteSentSub(viewModel.householdName) : l10n.inviteSub(viewModel.householdName),
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
            InviteForm(
              invite: invite,
              onSend: viewModel.send.execute,
              onResend: viewModel.resend.execute,
              onCancel: viewModel.cancel.execute,
              sendButton: (send) => PnButton(label: l10n.sendInvitation, onPressed: send),
              after: PnButton(label: l10n.ok, onPressed: () => Navigator.pop(context)),
            ),
          ],
        );
      },
    );
  }
}
