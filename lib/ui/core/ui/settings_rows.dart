import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'buttons.dart';
import 'controls.dart';
import 'pn_icon.dart';

/// Titled card grouping settings rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(title, style: PnText.sheetTitle.copyWith(color: PnColors.terra)),
        ),
        SettingsCard(children: children),
      ],
    );
  }
}

/// Snow card of rows, split by the soft cream divider: a settings group, or
/// the actions of a list's or note's menu.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PnColors.snow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PnColors.peachLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) const SoftDivider(indent: 12), child],
        ],
      ),
    );
  }
}

/// 2 px cream line with rounded ends: between the rows of a group, above
/// "Created by".
class SoftDivider extends StatelessWidget {
  const SoftDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: indent),
      decoration: BoxDecoration(color: PnColors.cream100, borderRadius: BorderRadius.circular(1)),
    );
  }
}

/// Icon, title, optional subtitle/value, and a chevron when tappable.
/// Pressed, it turns peach. [dimmed]: the icon, title, value and trailing
/// widget fade to 40 % but the subtitle stays, since it says why; a dimmed
/// row can't be tapped and has no chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.dimmed = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final String? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final lead =
        leading ?? (icon != null ? PnIcon(icon!, color: danger ? PnColors.danger : PnColors.terra, size: 22) : null);
    Widget faded(Widget child) =>
        AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: dimmed ? 0.4 : 1, child: child);
    final tap = dimmed ? null : onTap;
    return Pressable(
      onTap: tap,
      scale: 0.99,
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: pressed ? PnColors.peach : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (lead != null) ...[faded(SizedBox(width: 24, child: Center(child: lead))), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  faded(
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: danger ? PnColors.danger : PnColors.ink,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: PnText.meta.copyWith(height: 1.35)),
                  ],
                ],
              ),
            ),
            if (value != null)
              faded(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: PnColors.terraDark),
                  ),
                ),
              ),
            if (trailing != null) faded(trailing!),
            if (tap != null && trailing == null && !danger)
              const PnIcon(PnIcons.chevronRight, color: PnColors.terraDark, size: 16),
          ],
        ),
      ),
    );
  }
}

/// A value edited in place: pencil, then field + Cancel / Save.
class EditableRow extends StatefulWidget {
  const EditableRow({super.key, required this.icon, required this.label, required this.value, required this.onSave});

  final String icon;
  final String label;
  final String value;
  final ValueChanged<String> onSave;

  @override
  State<EditableRow> createState() => _EditableRowState();
}

class _EditableRowState extends State<EditableRow> {
  bool _editing = false;
  String? _error;
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).cantBeEmpty);
      return;
    }
    widget.onSave(text);
    setState(() => _editing = false);
  }

  void _cancel() => setState(() {
    _controller.text = widget.value;
    _error = null;
    _editing = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: _editing ? const EdgeInsets.fromLTRB(12, 10, 12, 12) : const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // At least 42 px, taller when the phone's text size needs it.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Center(child: PnIcon(widget.icon, color: PnColors.terra, size: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.label, style: PnText.meta),
                      if (!_editing) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: PnColors.ink),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_editing)
                  IconChip(
                    onPressed: () => setState(() {
                      _controller.text = widget.value;
                      _editing = true;
                    }),
                    background: PnColors.peach,
                    label: l10n.editField(widget.label),
                    child: const PnIcon(PnIcons.pencil, color: PnColors.terra, size: 20),
                  ),
              ],
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 10),
            PnTextField(
              controller: _controller,
              autofocus: true,
              error: _error,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PnButton(
                    label: l10n.cancel,
                    kind: PnButtonKind.tertiary,
                    foreground: PnColors.terra,
                    compact: true,
                    onPressed: _cancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PnButton(label: l10n.save, compact: true, onPressed: _save),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
