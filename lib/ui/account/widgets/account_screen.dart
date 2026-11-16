import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/settings_rows.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../../settings/view_models/settings_viewmodel.dart';
import '../../settings/widgets/settings_parts.dart';

/// First name and avatar color can change; the email is shown, not edited.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final vm = viewModel;
    final partner = vm.partner;
    final date = deletionDateLabel(context, DateTime.now().add(const Duration(days: 15)));
    final ok = await showPnSheet<bool>(
      context,
      ConfirmSheet(
        title: l10n.deleteAccountQuestion,
        confirmLabel: l10n.deleteMyAccount,
        cancelLabel: l10n.cancel,
        highlight: l10n.accountDeletedOn(date),
        lines: [
          partner != null ? l10n.sharedStayIn(vm.householdName, partner.name) : l10n.lastMemberDelete(vm.householdName),
          ?personalLine(l10n, vm),
          l10n.deactivatedFor15Days,
        ],
      ),
    );
    if (ok != true) return;
    await vm.deleteAccount();
    if (context.mounted) context.go(Routes.settings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final deletion = vm.deletionDate;
        return SettingsPage(
          back: l10n.settings,
          onBack: () => context.go(Routes.settings),
          title: l10n.accountTitle,
          children: [
            if (deletion != null)
              DeletionBanner(
                date: deletion,
                onCancel: () {
                  vm.cancelDeletion();
                  showToast(context, l10n.deletionCancelled);
                },
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
              decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(vm.me.color),
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    builder: (context, s, child) => Transform.scale(scale: s, child: child),
                    child: Avatar.of(vm.me, size: 88, ring: PnColors.snow),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final c in PnColors.avatars) ...[
                        Semantics(
                          button: true,
                          selected: vm.me.color == c.toARGB32(),
                          label: l10n.avatarColor,
                          child: GestureDetector(
                            onTap: () => vm.setColor(c.toARGB32()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                boxShadow: vm.me.color == c.toARGB32()
                                    ? [
                                        BoxShadow(color: c, spreadRadius: 5),
                                        const BoxShadow(color: PnColors.peach, spreadRadius: 3),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SettingsGroup(
              title: l10n.profileSection,
              children: [
                EditableRow(
                  icon: PnIcons.user,
                  label: l10n.firstName,
                  value: vm.me.name,
                  onSave: (name) {
                    vm.setName(name);
                    showToast(context, l10n.firstNameSaved);
                  },
                ),
                SettingsRow(icon: PnIcons.mail, title: vm.email),
              ],
            ),
            SettingsGroup(
              title: l10n.signInSection,
              children: [
                SettingsRow(icon: PnIcons.lock, title: l10n.codeByEmail, subtitle: l10n.codeByEmailSub),
                SettingsRow(icon: PnIcons.logOut, title: l10n.logOut, onTap: vm.signOut),
                if (deletion == null)
                  SettingsRow(
                    icon: PnIcons.trash,
                    title: l10n.deleteMyAccount,
                    subtitle: l10n.fifteenDays,
                    danger: true,
                    onTap: () => _delete(context),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
