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
  sun('EnvironmentSun');

  const ListIcon(this.asset);

  final String asset;
}

/// The five list colors, in picker order: orange, green, yellow, red,
/// brown. Stored by name.
enum ListColor { peach, sage, mustard, rose, cocoa }

/// Home shows the pinned lists, this many at most, so "Today" stays
/// visible without scrolling.
const maxPinnedLists = 4;

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
    DateTime? Function()? day,
    Reminder? Function()? reminder,
  }) => TaskList(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    isShared: isShared ?? this.isShared,
    pinned: pinned ?? this.pinned,
    day: day != null ? day() : this.day,
    reminder: reminder != null ? reminder() : this.reminder,
    ownerId: ownerId,
    createdAt: createdAt,
  );
}
