import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/household.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/invite_form.dart';
import '../../core/ui/mascot.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/settings_rows.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../../invite/widgets/invite_sheet.dart';
import '../view_models/settings_viewmodel.dart';
import 'settings_parts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  Future<void> _leave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final vm = viewModel;
    final partner = vm.partner;
    final ok = await showPnSheet<bool>(
      context,
      ConfirmSheet(
        title: l10n.leaveHouseholdQuestion,
        confirmLabel: l10n.leaveHousehold,
        cancelLabel: l10n.cancel,
        lines: [
          partner != null ? l10n.sharedStayIn(vm.householdName, partner.name) : l10n.lastMemberLeave(vm.householdName),
          if (partner != null) ?personalLine(l10n, vm),
          l10n.keepAccount,
        ],
      ),
    );
    if (ok == true) await vm.leaveHousehold();
  }

  Future<void> _removePartner(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final partner = viewModel.partner;
    if (partner == null) return;
    final ok = await showPnSheet<bool>(
      context,
      ConfirmSheet(
        title: l10n.removeQuestion(partner.name),
        confirmLabel: l10n.removeNamed(partner.name),
        cancelLabel: l10n.cancel,
        lines: [l10n.loseAccess(partner.name, viewModel.householdName), l10n.sharedStayInHousehold],
      ),
    );
    if (ok != true) return;
    await viewModel.removePartner();
    if (context.mounted) showToast(context, l10n.wasRemoved(partner.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final partner = vm.partner;
        final invite = vm.invite;
        final deletion = vm.deletionDate;
        final prefs = vm.notifications;
        Widget memberAvatar(Member m) => SizedBox(width: 36, child: Center(child: Avatar.of(m, size: 32)));
        return SettingsPage(
          back: l10n.home,
          onBack: () => context.go(Routes.home),
          title: l10n.settingsTitle,
          children: [
            Pressable(
              onTap: () => context.go(Routes.account),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: PnColors.peach, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Avatar.of(vm.me, size: 56, ring: PnColors.snow),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vm.me.name}.',
                            style: PnText.section.copyWith(color: PnColors.terraDark, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.myAccount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: PnColors.terraDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 20),
                  ],
                ),
              ),
            ),
            if (deletion != null) DeletionBanner(date: deletion, onCancel: () => _cancelDeletion(context)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsGroup(
                  title: l10n.householdSection,
                  children: [
                    EditableRow(
                      icon: 'NavigationHouse01',
                      label: l10n.householdName,
                      value: vm.householdName,
                      onSave: (name) {
                        vm.renameHousehold(name);
                        showToast(context, l10n.householdRenamed);
                      },
                    ),
                    SettingsRow(
                      title: vm.me.name,
                      subtitle: partner == null ? l10n.justYouForNow : l10n.youLabel,
                      leading: memberAvatar(vm.me),
                    ),
                    if (partner != null)
                      SettingsRow(
                        title: partner.name,
                        subtitle: l10n.member,
                        leading: memberAvatar(partner),
                        trailing: Pressable(
                          onTap: () => _removePartner(context),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: PnColors.danger, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PnIcon(PnIcons.close, color: PnColors.danger, size: 14),
                                const SizedBox(width: 6),
                                Text(l10n.remove, style: PnText.pill.copyWith(color: PnColors.danger)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (invite != null)
                      InviteRow(
                        flat: true,
                        invite: invite,
                        onResend: () {
                          vm.resendInvite();
                          showToast(context, l10n.invitationResent);
                        },
                        onCancel: () {
                          vm.cancelInvite();
                          showToast(context, l10n.invitationCancelled);
                        },
                      )
                    else
                      SettingsRow(
                        icon: PnIcons.plus,
                        title: l10n.inviteSomeone,
                        subtitle: l10n.inviteSomeoneSub,
                        onTap: () => showInviteSheet(context),
                      ),
                    SettingsRow(
                      icon: PnIcons.logOut,
                      title: l10n.leaveHousehold,
                      danger: true,
                      onTap: () => _leave(context),
                    ),
                  ],
                ),
                if (partner != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(l10n.householdFullNote, style: PnText.meta.copyWith(height: 1.45)),
                  ),
              ],
            ),
            SettingsGroup(
              title: l10n.notificationsSection,
              children: [
                SettingsRow(
                  icon: PnIcons.notifications,
                  title: l10n.notifications,
                  subtitle: prefs.enabled ? l10n.notificationsOnAt(prefs.defaultTime) : l10n.notificationsOff,
                  onTap: () => context.go(Routes.notifications),
                ),
              ],
            ),
            SettingsGroup(
              title: l10n.aboutSection,
              children: [
                SettingsRow(
                  icon: PnIcons.document,
                  title: l10n.termsOfUse,
                  onTap: () => showToast(context, l10n.opensInBrowser),
                ),
                SettingsRow(
                  icon: PnIcons.lock,
                  title: l10n.privacyPolicy,
                  onTap: () => showToast(context, l10n.opensInBrowser),
                ),
                SettingsRow(
                  icon: PnIcons.mail,
                  title: l10n.contactAndBugs,
                  subtitle: 'hello@picnote.cc',
                  onTap: () => showToast(context, l10n.opensMailApp),
                ),
              ],
            ),
            Column(
              children: [
                const Face(MascotMood.happy, height: 28),
                const SizedBox(height: 10),
                Text(l10n.aboutFooter, textAlign: TextAlign.center, style: PnText.meta.copyWith(height: 1.45)),
              ],
            ),
          ],
        );
      },
    );
  }

  void _cancelDeletion(BuildContext context) {
    viewModel.cancelDeletion();
    showToast(context, AppLocalizations.of(context).deletionCancelled);
  }
}
