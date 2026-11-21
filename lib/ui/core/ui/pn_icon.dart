import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/models/task_list.dart';

/// Icon names bundled in assets/icons/ (from the design system).
abstract final class PnIcons {
  static const chevronRight = 'ArrowChevronRightMD';
  static const plus = 'EditAddPlus';
  static const document = 'FileFileDocument';
  static const check = 'InterfaceCheck';
  static const menu = 'MenuHamburgerMD';
  static const lock = 'InterfaceLock';
  static const bell = 'Bell';
  static const calendar = 'CalendarCalendar';
  static const calendarOutline = 'ListCalendar';
  static const clock = 'CalendarClock';
  static const notifications = 'CommunicationBell';
  static const mail = 'CommunicationMail';
  static const pencil = 'EditPencil';
  static const close = 'MenuCloseMD';
  static const logOut = 'InterfaceLogOut';
  static const trash = 'InterfaceTrashFull';
  static const user = 'UserUser01';
  static const info = 'WarningInfo';
  static const list = 'List';
  static const text = 'Text';
  static const heading = 'Heading';
  static const checkbox = 'Checkbox';
  static const link = 'Link';
  static const pin = 'InterfacePin';
  static const pinOff = 'InterfacePinOff';
  static const share = 'CommunicationShareIOSExport';
  static const code = 'InterfaceCode';
  static const paperPlane = 'CommunicationPaperPlane';
}

/// A design-system icon tinted with [color].
class PnIcon extends StatelessWidget {
  const PnIcon(this.name, {super.key, required this.color, this.size = 24, this.turns = 0});

  PnIcon.list(ListIcon icon, {Key? key, required Color color, double size = 28})
    : this(icon.asset, key: key, color: color, size: size);

  final String name;
  final Color color;
  final double size;

  /// Quarter turns, e.g. 2 to point a chevron left.
  final int turns;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
    return turns == 0 ? icon : RotatedBox(quarterTurns: turns, child: icon);
  }
}
