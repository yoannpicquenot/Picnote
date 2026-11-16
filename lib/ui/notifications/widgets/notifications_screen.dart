import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/settings_rows.dart';
import '../../settings/view_models/settings_viewmodel.dart';
import '../../settings/widgets/settings_parts.dart';

/// Master switch, default reminder time, and the partner's activity.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final prefs = vm.notifications;
        final partner = vm.partner;
        return SettingsPage(
          back: l10n.settings,
          onBack: () => context.go(Routes.settings),
          title: l10n.notificationsTitle,
          children: [
            SettingsGroup(
              title: l10n.generalSection,
              children: [
                SettingsRow(
                  icon: PnIcons.notifications,
                  title: l10n.allowNotifications,
                  subtitle: prefs.enabled ? l10n.allowNotificationsOn : l10n.allowNotificationsOff,
                  trailing: PnToggle(on: prefs.enabled),
                  onTap: () => vm.updateNotifications(prefs.copyWith(enabled: !prefs.enabled)),
                ),
              ],
            ),
            SettingsGroup(
              title: l10n.remindersSection,
              children: [
                SettingsRow(
                  icon: PnIcons.calendar,
                  title: l10n.dailyReminders,
                  subtitle: l10n.dailyRemindersSub,
                  dimmed: !prefs.enabled,
                  trailing: PnToggle(on: prefs.dailyReminders && prefs.enabled),
                  onTap: prefs.enabled
                      ? () => vm.updateNotifications(prefs.copyWith(dailyReminders: !prefs.dailyReminders))
                      : null,
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: prefs.enabled ? 1 : 0.4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 24, child: PnIcon(PnIcons.clock, color: PnColors.terra, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.defaultTime,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: PnColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(l10n.defaultTimeSub, style: PnText.meta.copyWith(height: 1.35)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in reminderTimes)
                                ChoicePill(
                                  label: t,
                                  selected: prefs.defaultTime == t,
                                  bg: PnColors.peach,
                                  fg: PnColors.terraDark,
                                  onTap: prefs.enabled
                                      ? () => vm.updateNotifications(prefs.copyWith(defaultTime: t))
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (partner != null)
              SettingsGroup(
                title: l10n.householdSection,
                children: [
                  SettingsRow(
                    icon: PnIcons.check,
                    title: l10n.whenPartnerEdits(partner.name),
                    subtitle: l10n.eachTime,
                    dimmed: !prefs.enabled,
                    trailing: PnToggle(on: prefs.partnerActivity && prefs.enabled),
                    onTap: prefs.enabled
                        ? () => vm.updateNotifications(prefs.copyWith(partnerActivity: !prefs.partnerActivity))
                        : null,
                  ),
                ],
              ),
            Text(l10n.phoneNotificationSettings, style: PnText.meta.copyWith(height: 1.45)),
          ],
        );
      },
    );
  }
}
