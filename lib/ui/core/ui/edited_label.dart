import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/dates.dart';

/// "just now", "12 min ago", "2 h ago", "yesterday", or a date.
String editedLabel(BuildContext context, DateTime at) {
  final l10n = AppLocalizations.of(context);
  final ago = DateTime.now().difference(at);
  if (ago.inMinutes < 1) return l10n.justNow;
  if (ago.inMinutes < 60) return l10n.minutesAgo(ago.inMinutes);
  if (daysFromToday(at) == 0) return l10n.hoursAgo(ago.inHours);
  if (daysFromToday(at) == -1) return l10n.yesterdayLower;
  return DateFormat.MMMd(l10n.localeName).format(at);
}
