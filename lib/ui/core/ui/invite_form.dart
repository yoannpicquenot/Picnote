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

/// Invitation sent by email and not accepted yet: address, status, Resend /
/// Cancel. The code has its own card ([CodeCard]), in the invite panel only.
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
    // Resend: peach, darker when pressed. Cancel: an outline that turns ink.
    Widget action(String label, VoidCallback onTap, {required bool filled}) => Pressable(
      onTap: onTap,
      scale: 0.98,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? (pressed ? PnColors.tonalPressed : PnColors.peach) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: pressed ? PnColors.ink : PnColors.line, width: 1.5),
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
                      invite.email,
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
                        Text(l10n.invitationPending, style: PnText.meta),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // From the email's left edge: the icon (24) and its gap (12).
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                Expanded(child: action(l10n.resend, onResend, filled: true)),
                const SizedBox(width: 8),
                Expanded(child: action(l10n.cancel, onCancel, filled: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Code to share" on peach, the code large, and a copy button.
class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.code, required this.onCopied});

  final String code;

  /// After copying: "Code copied".
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.codeToShare, style: PnText.meta.copyWith(color: PnColors.terraDark)),
                const SizedBox(height: 4),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontFamily: PnFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: 3,
                    color: PnColors.terraDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.copyCode,
            icon: const Icon(Icons.copy_rounded, size: 20, color: PnColors.terraDark),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              onCopied();
            },
          ),
        ],
      ),
    );
  }
}

/// The email field of the invite panel. [sendButton] receives the send
/// callback, called with a valid address only, so the caller lays it out
/// (next to a back button).
class InviteEmailForm extends StatefulWidget {
  const InviteEmailForm({super.key, required this.onSend, required this.sendButton, this.initialEmail = ''});

  final ValueChanged<String> onSend;
  final Widget Function(VoidCallback send) sendButton;

  /// The address of a cancelled invitation, to fix and send again.
  final String initialEmail;

  @override
  State<InviteEmailForm> createState() => _InviteEmailFormState();
}

class _InviteEmailFormState extends State<InviteEmailForm> {
  late final _email = TextEditingController(text: widget.initialEmail);
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
