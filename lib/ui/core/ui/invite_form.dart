import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/validation.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'controls.dart';
import 'pn_icon.dart';
import 'toast.dart';

/// Pending invitation: address (or "by code"), status, Resend / Cancel.
class InviteRow extends StatelessWidget {
  const InviteRow({super.key, required this.invite, required this.onResend, required this.onCancel, this.flat = false});

  final Invite invite;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  /// Inside a settings group instead of its own card.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget action(String label, VoidCallback onTap, {required bool filled}) => Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? PnColors.peach : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: PnColors.line, width: 1.5),
        ),
        child: Text(
          label,
          style: PnText.pill.copyWith(fontSize: 14, color: filled ? PnColors.terraDark : PnColors.ink),
        ),
      ),
    );
    return Container(
      padding: flat ? const EdgeInsets.fromLTRB(14, 8, 14, 12) : const EdgeInsets.all(14),
      decoration: flat
          ? null
          : BoxDecoration(
              color: PnColors.snow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PnColors.peachLine, width: 2),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 24, child: PnIcon(PnIcons.mail, color: PnColors.terra, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.byCode ? l10n.inviteByCodeRow : invite.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: PnColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: PnColors.terra, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(l10n.invitePendingStatus, style: PnText.meta),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                Flexible(
                  child: SelectableText(
                    l10n.inviteCode(invite.code),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: PnColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.copyCode,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18, color: PnColors.terra),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite.code));
                    showToast(context, l10n.codeCopied);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                // Nothing to send again without an address.
                if (!invite.byCode) ...[action(l10n.resend, onResend, filled: true), const SizedBox(width: 8)],
                action(l10n.cancel, onCancel, filled: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Email field to invite the other person, or the pending invitation once
/// sent. [sendButton] receives the send callback so callers can lay it out
/// (with a back button during onboarding).
class InviteForm extends StatefulWidget {
  const InviteForm({
    super.key,
    required this.invite,
    required this.onSend,
    required this.onResend,
    required this.onCancel,
    required this.sendButton,
    required this.after,
  });

  final Invite? invite;
  final ValueChanged<String> onSend;
  final VoidCallback onResend;
  final VoidCallback onCancel;
  final Widget Function(VoidCallback send) sendButton;
  final Widget after;

  @override
  State<InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<InviteForm> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = AppLocalizations.of(context).invalidEmail);
      return;
    }
    widget.onSend(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invite = widget.invite;
    if (invite != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InviteRow(
            invite: invite,
            onResend: () {
              widget.onResend();
              showTopToast(context, l10n.invitationResent);
            },
            onCancel: () {
              _email.text = invite.email;
              widget.onCancel();
            },
          ),
          const SizedBox(height: 18),
          Text(l10n.inviteEmailHelp, style: PnText.sub),
          const SizedBox(height: 18),
          widget.after,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PnTextField(
          controller: _email,
          hint: l10n.theirEmail,
          tall: true,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          error: _error,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 18),
        widget.sendButton(_send),
      ],
    );
  }
}
