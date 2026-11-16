/// What the person agreed to be notified about.
class NotificationPrefs {
  const NotificationPrefs({this.enabled = true, this.defaultTime = '9:00', this.partnerActivity = true});

  final bool enabled;

  /// Suggested when adding a reminder.
  final String defaultTime;

  /// A notification each time the other member checks or edits.
  final bool partnerActivity;

  NotificationPrefs copyWith({bool? enabled, String? defaultTime, bool? partnerActivity}) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    defaultTime: defaultTime ?? this.defaultTime,
    partnerActivity: partnerActivity ?? this.partnerActivity,
  );
}
