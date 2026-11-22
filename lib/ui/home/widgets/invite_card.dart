import 'package:flutter/material.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/pn_icon.dart';

/// "Invite your other half." on home, while nobody else is in the household:
/// "Invite" opens the invite panel. "Later" (the cross) puts it away until
/// the next sign-in.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.me, required this.onInvite, required this.onLater});

  final Member me;
  final VoidCallback onInvite;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Avatar.of(me, size: 40, ring: PnColors.peach),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: const DashedPlus(size: 40, background: PnColors.peach, color: PnColors.terraDark),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                // Clear of the cross.
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inviteTheOther,
                      style: PnText.sheetTitle.copyWith(color: PnColors.terraDark, height: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.inviteCardSub, style: PnText.sub.copyWith(color: PnColors.terraDark)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PnButton(label: l10n.invite, icon: PnIcons.plus, compact: true, onPressed: onInvite),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Pressable(
              onTap: onLater,
              scale: 0.9,
              semanticLabel: l10n.later,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Center(child: PnIcon(PnIcons.close, color: PnColors.terraDark, size: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
