import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/task.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/colors.dart';
import '../themes/theme.dart';
import 'avatar.dart';
import 'controls.dart';

/// A task: checkbox, title (tap to rename, or to check when [onRename] is
/// null), optional tag or author avatar, and a drag handle. Swipe left to
/// delete, where [onDelete] is given.
class TaskRow extends StatefulWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    this.onRename,
    this.onDelete,
    this.tag,
    this.author,
    this.handle,
    this.background = PnColors.cream,
  });

  final Task task;
  final VoidCallback onToggle;

  /// Null where tasks can only be checked (home's Today / Tomorrow).
  final ValueChanged<String>? onRename;

  /// Null on home's Today / Tomorrow: a swipe there changes page, and must
  /// not delete a task by mistake.
  final VoidCallback? onDelete;

  /// List name chip, on the home screen.
  final Widget? tag;

  /// Shown when someone else last changed the task.
  final Member? author;
  final Widget? handle;
  final Color background;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.task.title);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Takes the focus explicitly: autofocus does nothing while another task
  /// is still being edited, which then kept the keyboard.
  void _startEditing() {
    setState(() {
      _controller.text = widget.task.title;
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focus.requestFocus();
    });
  }

  void _save() {
    setState(() => _editing = false);
    final title = _controller.text.trim();
    if (title.isEmpty) {
      widget.onDelete?.call();
    } else if (title != widget.task.title) {
      widget.onRename?.call(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = widget.task;
    // The checkbox, tag and handle stand by the first line of the title, as
    // in notes, however many lines it takes.
    final lineHeight = MediaQuery.textScalerOf(context).scale(PnText.body.fontSize!) * PnText.body.height!;
    final firstLine = math.max(PnCheck.size, lineHeight);
    final titleTop = (firstLine - lineHeight) / 2;
    Widget atFirstLine(Widget child) => SizedBox(
      height: firstLine,
      child: OverflowBox(fit: OverflowBoxFit.deferToChild, minHeight: 0, maxHeight: double.infinity, child: child),
    );
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: widget.onDelete == null ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        color: PnColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Text(l10n.delete, style: PnText.pill.copyWith(color: PnColors.snow)),
      ),
      child: Container(
        color: widget.background,
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            atFirstLine(
              PnCheck(done: task.done, onTap: widget.onToggle, label: task.done ? l10n.markNotDone : l10n.markDone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _editing
                  ? Padding(
                      // The field's own padding already lowers the text.
                      padding: EdgeInsets.only(top: math.max(0, titleTop - 4)),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        style: PnText.body,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _focus.unfocus(),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: PnColors.terra, width: 2)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PnColors.terra, width: 2)),
                        ),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onRename == null
                          ? () => checkTapped(done: task.done, onTap: widget.onToggle)
                          : _startEditing,
                      child: Padding(
                        padding: EdgeInsets.only(top: titleTop),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: StrikeTitle(text: task.title, done: task.done),
                        ),
                      ),
                    ),
            ),
            if (widget.tag != null) ...[const SizedBox(width: 12), atFirstLine(widget.tag!)],
            if (widget.tag == null && widget.author != null) ...[
              const SizedBox(width: 12),
              atFirstLine(Avatar.of(widget.author!, size: 18)),
            ],
            if (widget.handle != null) ...[const SizedBox(width: 12), atFirstLine(widget.handle!)],
          ],
        ),
      ),
    );
  }
}

/// Six dots to drag a task.
class Grip extends StatelessWidget {
  const Grip({super.key, this.color = PnColors.grey500});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // Plain rows, not a GridView: a scroll view adds the status bar's
    // padding and pushed the dots out of sight on phones.
    final dot = Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final row = Row(mainAxisSize: MainAxisSize.min, children: [dot, const SizedBox(width: 3), dot]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [row, const SizedBox(height: 3), row, const SizedBox(height: 3), row],
      ),
    );
  }
}

/// Empty checkbox + field to append a task. Keeps focus after Enter.
class AddTaskRow extends StatefulWidget {
  const AddTaskRow({super.key, required this.onAdd, required this.placeholder, this.autofocus = false, this.onTyping});

  final ValueChanged<String> onAdd;

  /// The text as it is typed, empty again once added.
  final ValueChanged<String>? onTyping;
  final String placeholder;
  final bool autofocus;

  @override
  State<AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<AddTaskRow> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {});
      if (!_focus.hasFocus) _submit(keepFocus: false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit({required bool keepFocus}) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    widget.onTyping?.call('');
    if (keepFocus) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focus.hasFocus || _controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: active ? 1 : 0.35,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PnColors.terra, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              style: PnText.body,
              // Each new item starts with a capital.
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (text) {
                setState(() {});
                widget.onTyping?.call(text);
              },
              onSubmitted: (_) => _submit(keepFocus: true),
              decoration: InputDecoration.collapsed(
                hintText: widget.placeholder,
                hintStyle: PnText.body.copyWith(color: PnColors.placeholder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The item a housemate is typing, as they type it: their color, their
/// avatar, not a task yet.
class DraftTaskRow extends StatelessWidget {
  const DraftTaskRow({super.key, required this.text, required this.member});

  final String text;
  final Member member;

  @override
  Widget build(BuildContext context) {
    final color = Color(member.color);
    return Semantics(
      label: AppLocalizations.of(context).isTyping(member.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: PnText.body.copyWith(color: PnColors.muted, fontStyle: FontStyle.italic),
              ),
            ),
            Container(width: 2, height: 18, margin: const EdgeInsets.only(left: 1, right: 8), color: color),
            Avatar.of(member, size: 18),
          ],
        ),
      ),
    );
  }
}
