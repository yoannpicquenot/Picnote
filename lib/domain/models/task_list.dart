import 'reminder.dart';

/// Icons a list can wear, in picker order.
enum ListIcon {
  shoppingCart('InterfaceShoppingCart01'),
  house('NavigationHouse01'),
  paperPlane('CommunicationPaperPlane'),
  heart('InterfaceHeart01'),
  gift('InterfaceGift'),
  leaf('EnvironmentLeaf'),
  book('InterfaceBook'),
  coffee('EnvironmentCoffee'),
  suitcase('InterfaceSuitcase'),
  star('InterfaceStar'),
  calendar('ListCalendar'),
  apple('FoodApple'),

  /// No longer offered (the apple took its place); lists wearing it keep it.
  sun('EnvironmentSun');

  const ListIcon(this.asset);

  final String asset;

  /// The icons the picker offers, in order.
  static List<ListIcon> get pickable => [
    for (final i in values)
      if (i != sun) i,
  ];
}

/// The five list colors, in picker order: orange, green, yellow, red,
/// brown. Stored by name.
enum ListColor { peach, sage, mustard, rose, cocoa }

/// Home shows the pinned lists, this many at most, so "Today" stays
/// visible without scrolling.
const maxPinnedLists = 4;

/// The pinned lists of [lists], in their order on home: those never
/// arranged ([TaskList.pinOrder] null) first, in [lists]' order, then the
/// others by [TaskList.pinOrder], so that a list pinned now comes last.
List<TaskList> pinnedInOrder(Iterable<TaskList> lists) {
  final pinned = [
    for (final (i, l) in lists.indexed)
      if (l.pinned) (i, l),
  ];
  pinned.sort((a, b) {
    final (x, y) = (a.$2.pinOrder, b.$2.pinOrder);
    if (x == y) return a.$1.compareTo(b.$1);
    if (x == null) return -1;
    if (y == null) return 1;
    return x.compareTo(y);
  });
  return [for (final (_, l) in pinned) l];
}

/// Where a list pinned now goes: last on home.
int nextPinOrder(Iterable<TaskList> lists) {
  var next = 0;
  for (final l in lists) {
    final order = l.pinOrder;
    if (l.pinned && order != null && order >= next) next = order + 1;
  }
  return next;
}

/// A checklist, personal by default or shared with the household.
///
/// [day] puts it in "Today" / "Tomorrow" on the home screen; [reminder] is
/// independent and optional. [pinned] lists show on home.
class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    this.color = ListColor.rose,
    this.icon = ListIcon.heart,
    this.isShared = false,
    this.pinned = false,
    this.pinOrder,
    this.day,
    this.reminder,
    this.ownerId,
    this.createdAt,
  });

  final String id;
  final String name;
  final ListColor color;
  final ListIcon icon;
  final bool isShared;
  final bool pinned;

  /// Its place on home among the pinned lists, smallest first.
  final int? pinOrder;
  final DateTime? day;
  final Reminder? reminder;

  /// Who created it, and when: set by the server, so null on a list just
  /// created on this phone and not yet fetched back.
  final String? ownerId;
  final DateTime? createdAt;

  TaskList copyWith({
    String? name,
    ListColor? color,
    ListIcon? icon,
    bool? isShared,
    bool? pinned,
    int? Function()? pinOrder,
    DateTime? Function()? day,
    Reminder? Function()? reminder,
  }) => TaskList(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    isShared: isShared ?? this.isShared,
    pinned: pinned ?? this.pinned,
    pinOrder: pinOrder != null ? pinOrder() : this.pinOrder,
    day: day != null ? day() : this.day,
    reminder: reminder != null ? reminder() : this.reminder,
    ownerId: ownerId,
    createdAt: createdAt,
  );
}
