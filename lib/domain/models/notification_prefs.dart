/// What the person agreed to be notified about.
class NotificationPrefs {
  const NotificationPrefs({
    this.enabled = true,
    this.defaultTime = '9:00',
    this.partnerActivity = true,
    this.dailyReminders = true,
  });

  final bool enabled;

  /// Suggested when adding a reminder.
  final String defaultTime;

  /// A notification each time the other member checks or edits.
  final bool partnerActivity;

  /// Every 3 hours from 9:00 to 21:00, what is left for today and tomorrow.
  final bool dailyReminders;

  NotificationPrefs copyWith({bool? enabled, String? defaultTime, bool? partnerActivity, bool? dailyReminders}) =>
      NotificationPrefs(
        enabled: enabled ?? this.enabled,
        defaultTime: defaultTime ?? this.defaultTime,
        partnerActivity: partnerActivity ?? this.partnerActivity,
        dailyReminders: dailyReminders ?? this.dailyReminders,
      );
}
