import '../../domain/models/activity.dart';
import '../../domain/models/note.dart';
import '../../domain/models/notification_prefs.dart';
import '../../domain/models/reminder.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_list.dart';
import '../../domain/models/user.dart';

/// Conversions between Supabase rows (see supabase/migrations) and domain
/// models.
typedef Row = Map<String, dynamic>;

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);

String? _dateString(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Reminder? _reminder(Row r) {
  final date = _date(r['reminder_date']);
  final time = r['reminder_time'] as String?;
  return date == null || time == null ? null : Reminder(date: date, time: time);
}

Row _reminderRow(Reminder? r) => {'reminder_date': _dateString(r?.date), 'reminder_time': r?.time};

User userFromRow(Row r) =>
    User(id: r['id'] as String, email: r['email'] as String, name: r['name'] as String, color: r['color'] as int);

NotificationPrefs prefsFromRow(Row r) => NotificationPrefs(
  enabled: r['notify_enabled'] as bool,
  defaultTime: r['notify_default_time'] as String,
  partnerActivity: r['notify_partner_activity'] as bool,
);

Row prefsToRow(NotificationPrefs p) => {
  'notify_enabled': p.enabled,
  'notify_default_time': p.defaultTime,
  'notify_partner_activity': p.partnerActivity,
};

TaskList listFromRow(Row r) => TaskList(
  id: r['id'] as String,
  name: r['name'] as String,
  color: ListColor.values.asNameMap()[r['color']] ?? ListColor.rose,
  icon: ListIcon.values.asNameMap()[r['icon']] ?? ListIcon.heart,
  isShared: r['is_shared'] as bool,
  pinned: r['pinned'] as bool? ?? false,
  day: _date(r['day']),
  reminder: _reminder(r),
  ownerId: r['owner_id'] as String?,
  createdAt: switch (r['created_at']) {
    final String at => DateTime.parse(at).toLocal(),
    _ => null,
  },
);

Row listToRow(TaskList l) => {
  'id': l.id,
  'name': l.name,
  'color': l.color.name,
  'icon': l.icon.name,
  'is_shared': l.isShared,
  'pinned': l.pinned,
  'day': _dateString(l.day),
  ..._reminderRow(l.reminder),
};

Task taskFromRow(Row r) => Task(
  id: r['id'] as String,
  listId: r['list_id'] as String,
  title: r['title'] as String,
  done: r['done'] as bool,
  doneAt: switch (r['done_at']) {
    final String at => DateTime.parse(at).toLocal(),
    _ => null,
  },
  byId: r['by_id'] as String?,
  today: r['today'] as bool,
);

Row taskToRow(Task t, {required double position}) => {
  'id': t.id,
  'list_id': t.listId,
  'title': t.title,
  'done': t.done,
  'done_at': t.doneAt?.toUtc().toIso8601String(),
  'by_id': t.byId,
  'today': t.today,
  'position': position,
};

Note noteFromRow(Row r) => Note(
  id: r['id'] as String,
  title: r['title'] as String,
  authorId: r['author_id'] as String? ?? '',
  editedById: r['edited_by'] as String? ?? '',
  editedAt: DateTime.parse(r['edited_at'] as String).toLocal(),
  isShared: r['is_shared'] as bool,
  reminder: _reminder(r),
  blocks: blocksFromJson(r['blocks'] as List),
);

/// Everything but the author, which only changes on the server.
Row noteToRow(Note n) => {
  'id': n.id,
  'title': n.title,
  'is_shared': n.isShared,
  'edited_by': n.editedById.isEmpty ? null : n.editedById,
  'edited_at': n.editedAt.toUtc().toIso8601String(),
  'blocks': blocksToJson(n.blocks),
  ..._reminderRow(n.reminder),
};

List<NoteBlock> blocksFromJson(List json) => [
  for (final b in json.cast<Row>())
    NoteBlock(
      id: b['id'] as String,
      type: NoteBlockType.values.asNameMap()[b['type']] ?? NoteBlockType.text,
      text: b['text'] as String? ?? '',
      done: b['done'] as bool? ?? false,
      styles: [
        for (final s in (b['styles'] as List? ?? const []).cast<List>())
          if (InlineStyle.values.asNameMap()[s[2]] case final style?) StyleRange(s[0] as int, s[1] as int, style),
      ],
      level: b['level'] as int? ?? 1,
      color: HeadingColor.values.asNameMap()[b['color']] ?? HeadingColor.terra,
      cells: [
        for (final row in (b['cells'] as List? ?? const []).cast<List>()) [for (final c in row) c as String? ?? ''],
      ],
    ),
];

List<Row> blocksToJson(List<NoteBlock> blocks) => [
  for (final b in blocks)
    {
      'id': b.id,
      'type': b.type.name,
      'text': b.text,
      'done': b.done,
      // [start, end, "bold"], only when there are some.
      if (b.styles.isNotEmpty)
        'styles': [
          for (final s in b.styles) [s.start, s.end, s.style.name],
        ],
      // Only what differs from the defaults.
      if (b.type == NoteBlockType.heading && b.level != 1) 'level': b.level,
      if (b.type == NoteBlockType.heading && b.color != HeadingColor.terra) 'color': b.color.name,
      if (b.type == NoteBlockType.table) 'cells': b.cells,
    },
];

Activity activityFromRow(Row r) => Activity(
  isNote: r['note_id'] != null,
  itemId: (r['list_id'] ?? r['note_id']) as String,
  actorId: r['actor_id'] as String? ?? '',
  verb: ActivityVerb.values.asNameMap()[r['verb']] ?? ActivityVerb.edit,
  item: r['item'] as String?,
  at: DateTime.parse(r['at'] as String).toLocal(),
);
