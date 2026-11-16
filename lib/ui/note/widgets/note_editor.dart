import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
// ignore: implementation_imports, not exported, and the only way to keep undo to this user's own changes.
import 'package:flutter_quill/src/document/history.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/selection_handles.dart';
import '../view_models/note_viewmodel.dart';
import 'format_bar.dart';
import 'note_delta.dart';
import 'note_markdown.dart';
import 'note_table.dart';

/// What the screen shows above the keyboard: the formatting bar while text
/// is selected, the block menu while a line starts with "/".
typedef EditorBars = ({bool format, String? slash});

/// The body of a note, one document so that a selection can span lines.
/// Each line is a block: text, heading, bullet, checkbox or table. Enter
/// keeps a list going, Enter on an empty item ends it, "- " starts a
/// bullet list, and "/" at the start of a line opens the block menu.
class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, required this.viewModel, required this.blocks, required this.bars});

  final NoteViewModel viewModel;
  final List<NoteBlock> blocks;

  /// Owned by the screen, which draws the bars.
  final ValueNotifier<EditorBars> bars;

  @override
  State<NoteEditor> createState() => NoteEditorState();
}

class NoteEditorState extends State<NoteEditor> {
  late final controller = _NoteController(
    document: _NoteDocument.fromDelta(blocksToDelta(widget.blocks)),
    selection: const TextSelection.collapsed(offset: 0),
    newId: () => vm.newBlockId(),
    onPaste: () => _paste(),
  );
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final StreamSubscription<DocChange> _changes;

  NoteViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _changes = controller.changes.listen((change) {
      if (change.source != ChangeSource.local) return;
      _typed();
      _autoBullet();
      _save();
    });
    controller.addListener(_selectionChanged);
    _focus.addListener(_selectionChanged);
  }

  @override
  void didUpdateWidget(NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Not while building: the bar above the keyboard listens to the editor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyRemote();
      // Once the editor has laid out what came in.
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => _placeOverlays())
        ..scheduleFrame();
    });
  }

  /// Runs while this user types here, and a little after.
  Timer? _typing;

  /// Someone else's change waits for [_typing] to end.
  bool _remoteWaiting = false;

  static const _pause = Duration(milliseconds: 800);

  /// The latest version brought in, or found already there.
  List<NoteBlock>? _seen;

  void _typed() {
    _typing?.cancel();
    _typing = Timer(_pause, () {
      if (mounted && _remoteWaiting) _applyRemote();
    });
  }

  /// Someone else's change (as they type it, or else as saved) comes in.
  /// While this user types here too, it waits for a pause, then goes in
  /// as a diff, so that their caret stays where it was. Both typing in the
  /// very same instant still means the last one wins.
  void _applyRemote() {
    _remoteWaiting = false;
    final blocks = vm.live?.blocks ?? widget.blocks;
    // Each version goes in once: what the housemate typed lingers a few
    // seconds, and must not undo what this user typed since.
    if (identical(blocks, _seen)) return;
    if (sameBlocks(_blocks(), blocks)) {
      _seen = blocks;
      return;
    }
    if (_focus.hasFocus && (_typing?.isActive ?? false)) {
      _remoteWaiting = true;
      return;
    }
    _seen = blocks;
    final change = controller.document.toDelta().diff(blocksToDelta(blocks));
    final sel = controller.selection;
    // Only shown: Quill would otherwise open the keyboard, as if this user
    // had made the change. (Its ignoreFocusOnTextChange also skips redrawing.)
    controller.skipRequestKeyboard = true;
    _composingRemote = true;
    controller.compose(
      change,
      sel.copyWith(
        baseOffset: change.transformPosition(sel.baseOffset),
        extentOffset: change.transformPosition(sel.extentOffset),
      ),
      ChangeSource.remote,
    );
    _composingRemote = false;
    controller.skipRequestKeyboard = false;
  }

  /// While someone else's change goes in: the page stays where this user
  /// scrolled it, rather than following their caret.
  bool _composingRemote = false;

  final _quill = GlobalKey<QuillEditorState>();
  final _stack = GlobalKey();

  /// The housemate's cursor, in this widget, while they type.
  Rect? _caret;

  /// Where "Type / for blocks" goes: on the empty line being typed in.
  Rect? _hint;

  /// The keyboard's height, last time: when it grows, the caret is kept
  /// in view.
  double _keyboard = 0;

  RenderEditor? get _renderEditor {
    final editor = _quill.currentState?.editableTextKey.currentState?.renderEditor;
    return editor != null && editor.attached ? editor : null;
  }

  /// [offset]'s caret, in this widget.
  Rect? _caretRect(int offset) {
    final editor = _renderEditor;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    if (editor == null || stack == null) return null;
    final rect = editor.getLocalRectForCaret(TextPosition(offset: offset.clamp(0, controller.document.length - 1)));
    return stack.globalToLocal(editor.localToGlobal(rect.topLeft)) & rect.size;
  }

  void _placeOverlays() {
    if (!mounted) return;
    final remote = vm.live?.cursor;
    final caret = remote == null ? null : _caretRect(remote);
    final line = _line;
    final sel = controller.selection;
    // An empty plain line, not the first of an empty note (which has its
    // own placeholder).
    final showHint =
        _focus.hasFocus &&
        sel.isValid &&
        sel.isCollapsed &&
        line != null &&
        line.length == 1 &&
        line.style.isEmpty &&
        controller.document.length > 1;
    final hint = showHint ? _caretRect(sel.baseOffset) : null;
    final mine = _focus.hasFocus && sel.isValid && sel.isCollapsed ? _caretRect(sel.baseOffset) : null;
    if (caret != _caret || hint != _hint || mine != _mine) {
      setState(() {
        _caret = caret;
        _hint = hint;
        _mine = mine;
      });
    }
  }

  /// This user's caret, drawn over the text (Quill draws it under, where
  /// letters hide it), with a handle to slide it along with a finger.
  Rect? _mine;

  /// The handle shows once the caret is placed by a tap, not while typing,
  /// and goes after a few seconds, as on Android.
  bool _handle = false;
  Timer? _handleTimer;
  late String _textSeen = controller.document.toPlainText();

  void _caretMoved() {
    final text = controller.document.toPlainText();
    final typed = text != _textSeen;
    _textSeen = text;
    _handleTimer?.cancel();
    final show = !typed && _focus.hasFocus && controller.selection.isCollapsed;
    if (show) _handleTimer = Timer(const Duration(seconds: 4), () => _setHandle(false));
    _setHandle(show);
  }

  void _setHandle(bool show) {
    if (mounted && show != _handle) setState(() => _handle = show);
  }

  /// From the finger to the caret's middle, as the drag starts.
  Offset _grab = Offset.zero;

  void _dragStart(DragStartDetails details) {
    _handleTimer?.cancel();
    final editor = _renderEditor;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final mine = _mine;
    if (editor == null || stack == null || mine == null) return;
    _grab = stack.localToGlobal(mine.center) - details.globalPosition;
  }

  void _dragUpdate(DragUpdateDetails details) {
    final editor = _renderEditor;
    if (editor == null) return;
    final position = editor.getPositionForOffset(details.globalPosition + _grab);
    controller.updateSelection(TextSelection.collapsed(offset: position.offset), ChangeSource.local);
  }

  void _dragEnd([DragEndDetails? _]) {
    _handleTimer?.cancel();
    _handleTimer = Timer(const Duration(seconds: 4), () => _setHandle(false));
  }

  @override
  void dispose() {
    _typing?.cancel();
    _handleTimer?.cancel();
    _changes.cancel();
    controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<NoteBlock> _blocks() => deltaToBlocks(controller.document.toDelta(), widget.blocks, vm.newBlockId);

  void _save() => vm.setBlocks(_blocks(), cursor: controller.selection.extentOffset);

  Line? get _line {
    final sel = controller.selection;
    if (!sel.isValid) return null;
    final node = controller.document.queryChild(sel.baseOffset).node;
    return node is Line ? node : null;
  }

  void _selectionChanged() {
    _updateBars();
    _caretMoved();
    final follow = !_composingRemote;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placeOverlays();
      if (follow) _keepCaretVisible();
    });
  }

  /// The page scrolls, not the editor: keeps the caret above the keyboard
  /// and the bar on top of it, as lines are added.
  void _keepCaretVisible() {
    if (!mounted || !_focus.hasFocus || !controller.selection.isValid) return;
    final editor = _renderEditor;
    if (editor == null) return;
    final rect = editor.getLocalRectForCaret(controller.selection.extent);
    editor.showOnScreen(
      rect: Rect.fromLTRB(rect.left, rect.top - 24, rect.right, rect.bottom + FormatBar.height + 24),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _updateBars() {
    final sel = controller.selection;
    final focused = _focus.hasFocus && sel.isValid;
    String? slash;
    if (focused && sel.isCollapsed) {
      final text = _line?.toPlainText().replaceAll('\n', '') ?? '';
      if (text.startsWith('/') && !text.contains(' ')) slash = text.substring(1);
    }
    // Also with no selection: B, I or U then turn the style on or off for
    // what is typed next.
    final bars = (format: focused && slash == null, slash: slash);
    if (bars != widget.bars.value) widget.bars.value = bars;
  }

  /// "- " typed at the start of a plain line makes it a bullet.
  void _autoBullet() {
    final sel = controller.selection;
    final line = _line;
    if (!sel.isCollapsed || line == null || line.style.isNotEmpty) return;
    final start = line.documentOffset;
    if (sel.baseOffset != start + 2 || !line.toPlainText().startsWith('- ')) return;
    // After this change is handled, not in the middle of it.
    scheduleMicrotask(() {
      if (controller.document.getPlainText(start, 2) != '- ') return;
      controller.replaceText(start, 2, '', TextSelection.collapsed(offset: start));
      controller.formatText(start, 0, Attribute.ul);
    });
  }

  /// From the title's Enter.
  void focusStart() {
    _focus.requestFocus();
    controller.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);
  }

  static Attribute<dynamic> _attribute(InlineStyle style) => switch (style) {
    InlineStyle.bold => Attribute.bold,
    InlineStyle.italic => Attribute.italic,
    InlineStyle.underline => Attribute.underline,
  };

  /// From the formatting bar: applies to the selection.
  void toggleStyle(InlineStyle style) {
    final attribute = _attribute(style);
    final on = controller.getSelectionStyle().attributes.containsKey(attribute.key);
    controller.formatSelection(on ? Attribute.clone(attribute, null) : attribute);
  }

  bool isActive(InlineStyle style) => controller.getSelectionStyle().attributes.containsKey(_attribute(style).key);

  /// The heading level of the line being typed in, null when it is not one.
  int? get headingLevel {
    final level = _line?.style.attributes[Attribute.header.key]?.value;
    return level is int ? level : null;
  }

  /// The color of the heading being typed in.
  HeadingColor get headingColorNow {
    final value = controller.getSelectionStyle().attributes[Attribute.color.key]?.value;
    for (final c in HeadingColor.values) {
      if (headingColorValue(c) == value?.toString().toUpperCase()) return c;
    }
    return HeadingColor.terra;
  }

  /// From the start of the first selected line to the end of the last.
  (int, int) get _selectedLines {
    final doc = controller.document;
    final sel = controller.selection;
    final first = doc.queryChild(sel.start).node;
    final last = doc.queryChild(sel.end).node;
    final start = first?.documentOffset ?? sel.start;
    final end = last == null ? sel.end : last.documentOffset + last.length - 1;
    return (start, end);
  }

  /// Makes the selected lines headings of [level], or plain text again
  /// (null), which drops their color.
  void setHeading(int? level) {
    if (level == null) {
      controller.formatSelection(Attribute.clone(Attribute.header, null));
      final (start, end) = _selectedLines;
      controller.formatText(start, end - start, const ColorAttribute(null));
    } else {
      controller
        ..formatSelection(Attribute.clone(Attribute.list, null))
        ..formatSelection(HeaderAttribute(level: level));
    }
    _updateBars();
  }

  /// Colors the selected headings, whole lines.
  void setHeadingColor(HeadingColor color) {
    final (start, end) = _selectedLines;
    final sel = controller.selection;
    controller
      ..formatText(start, end - start, ColorAttribute(headingColorValue(color)))
      // What is typed next takes it too.
      ..updateSelection(sel, ChangeSource.local);
  }

  bool get canUndo => controller.hasUndo;

  bool get canRedo => controller.hasRedo;

  void undo() {
    controller.undo();
    _save();
  }

  void redo() {
    controller.redo();
    _save();
  }

  /// From the "/" menu: the "/…" typed goes, the line takes [type] (and
  /// [level], for a heading), and typing goes on in it. A table goes on
  /// its own line, followed by an empty one to type on.
  void pickBlock(NoteBlockType type, {int level = 1}) {
    final line = _line;
    if (line == null) return;
    final start = line.documentOffset;
    controller.replaceText(start, line.length - 1, '', TextSelection.collapsed(offset: start));
    if (type == NoteBlockType.table) {
      for (final attribute in lineAttributes(NoteBlockType.text)) {
        controller.formatText(start, 0, attribute);
      }
      controller
        ..replaceText(start, 0, tableBlockEmbed(newTableCells), null)
        ..replaceText(start + 1, 0, '\n', TextSelection.collapsed(offset: start + 2));
      _focus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => _editTable(start, newTableCells));
      return;
    }
    for (final attribute in lineAttributes(type, level: level)) {
      controller.formatText(start, 0, attribute);
    }
    _focus.requestFocus();
  }

  Future<void> _editTable(int offset, List<List<String>> cells) async {
    if (!mounted) return;
    await editTable(context, controller, offset, cells);
  }

  /// Copied as Markdown; pasted Markdown keeps its headings, lists,
  /// checkboxes and tables.
  Future<bool> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || !_looksLikeMarkdown(text)) return false;
    final blocks = markdownToBlocks(text, vm.newBlockId);
    var delta = blocksToDelta(blocks);
    // The last line, plain, goes on in the line pasted into.
    if (blocks.isNotEmpty && blocks.last.type == NoteBlockType.text) delta = delta.slice(0, delta.length - 1);
    final sel = controller.selection;
    controller.replaceText(
      sel.start,
      sel.end - sel.start,
      delta,
      TextSelection.collapsed(offset: sel.start + delta.length),
    );
    return true;
  }

  static final _markdownLine = RegExp(r'^\s*(#{1,6}\s|[-*+•]\s|\|.*\|\s*$)', multiLine: true);

  static bool _looksLikeMarkdown(String text) =>
      text.contains('\n') || _markdownLine.hasMatch(text) || text.contains('**') || text.contains('<u>');

  /// Tapping below the note continues it, on a new text line unless the
  /// last one is already an empty one.
  void _tapTail() {
    final doc = controller.document;
    final end = doc.length - 1;
    final last = doc.queryChild(end).node;
    final lastIsEmptyText = last is Line && last.length == 1 && last.style.isEmpty;
    _focus.requestFocus();
    if (lastIsEmptyText) {
      controller.updateSelection(TextSelection.collapsed(offset: end), ChangeSource.local);
      return;
    }
    controller.replaceText(end, 0, '\n', TextSelection.collapsed(offset: end + 1));
    for (final attribute in lineAttributes(NoteBlockType.text)) {
      controller.formatText(end + 1, 0, attribute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard > _keyboard) WidgetsBinding.instance.addPostFrameCallback((_) => _keepCaretVisible());
    _keyboard = keyboard;
    const base = TextStyle(
      fontFamily: PnFonts.body,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.45,
      color: PnColors.ink,
    );
    const lineGap = VerticalSpacing(0, 6);
    const none = VerticalSpacing(0, 0);
    const flat = HorizontalSpacing(0, 0);
    DefaultTextBlockStyle heading(double size, double top) => DefaultTextBlockStyle(
      TextStyle(
        fontFamily: PnFonts.display,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1.2,
        color: PnColors.terra,
      ),
      flat,
      VerticalSpacing(top, 6),
      none,
      null,
    );
    // The handle can hang below the last line, over the space under it.
    return Stack(
      key: _stack,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuillEditor(
              key: _quill,
              controller: controller,
              focusNode: _focus,
              scrollController: _scroll,
              config: QuillEditorConfig(
                // The page scrolls, with the title above.
                scrollable: false,
                placeholder: l10n.blockTextHint,
                textCapitalization: TextCapitalization.sentences,
                // Room for the bar above the keyboard.
                scrollBottomInset: FormatBar.height + 20,
                textSelectionControls: pnSelectionControls,
                // Drawn by [_Caret], over the text.
                showCursor: false,
                // A tap shows the handle, even where the caret already was.
                onTapUp: (_, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !controller.selection.isCollapsed) return;
                    _handleTimer?.cancel();
                    _handleTimer = Timer(const Duration(seconds: 4), () => _setHandle(false));
                    _setHandle(true);
                  });
                  return false;
                },
                embedBuilders: [TableEmbedBuilder(onEdit: _editTable)],
                customStyles: DefaultStyles(
                  paragraph: const DefaultTextBlockStyle(base, flat, lineGap, none, null),
                  placeHolder: DefaultTextBlockStyle(
                    base.copyWith(color: PnColors.placeholder),
                    flat,
                    lineGap,
                    none,
                    null,
                  ),
                  h1: heading(24, 14),
                  h2: heading(21, 12),
                  h3: heading(18, 10),
                  h4: heading(16, 8),
                  lists: DefaultListBlockStyle(
                    base,
                    flat,
                    lineGap,
                    lineGap,
                    null,
                    null,
                    // The dot ends 10px in, then 16px before the text; a checkbox
                    // needs its own width.
                    indentWidthBuilder: (block, context, count, numberPointWidth) =>
                        HorizontalSpacing(block.style.attributes[Attribute.list.key] == Attribute.ul ? 26 : 40, 0),
                  ),
                  bold: const TextStyle(fontWeight: FontWeight.w700),
                  italic: const TextStyle(fontStyle: FontStyle.italic),
                  underline: const TextStyle(decoration: TextDecoration.underline),
                  link: const TextStyle(
                    color: PnColors.terraDark,
                    decoration: TextDecoration.underline,
                    decorationColor: PnColors.terraDark,
                  ),
                ),
                // A checked item is struck through, as on lists.
                customStyleBuilder: (attribute) => attribute == Attribute.checked
                    ? const TextStyle(
                        color: PnColors.muted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: PnColors.terra,
                        decorationThickness: 2,
                      )
                    : const TextStyle(),
                // ignore: experimental_member_use, the only way to draw the app's own checkbox.
                customLeadingBlockBuilder: _leading,
              ),
            ),
            GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapTail, child: const SizedBox(height: 80)),
          ],
        ),
        if (_hint case final hint?)
          Positioned(
            left: hint.left + 2,
            top: hint.top,
            child: IgnorePointer(
              child: Text(l10n.blockTextHint, style: base.copyWith(color: PnColors.placeholder)),
            ),
          ),
        if ((_caret, vm.typist) case (final caret?, final typist?))
          Positioned.fromRect(rect: caret, child: _RemoteCaret(typist)),
        if (_mine case final mine?) ...[
          // Keyed by place: moved or typed, it shows at once.
          Positioned.fromRect(
            rect: mine,
            child: IgnorePointer(child: _Caret(key: ValueKey(mine.topLeft))),
          ),
          if (_handle)
            Positioned(
              // A finger-sized touch area around the drop.
              left: mine.center.dx - CaretHandle.size / 2 - 14,
              top: mine.bottom,
              // Part of the editor: touching it does not unfocus it.
              child: TextFieldTapRegion(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _dragStart,
                  onPanUpdate: _dragUpdate,
                  onPanEnd: _dragEnd,
                  onPanCancel: _dragEnd,
                  child: const Padding(padding: EdgeInsets.fromLTRB(14, 0, 14, 18), child: CaretHandle()),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// The app's own checkbox and bullet in front of list lines.
  Widget? _leading(Node node, LeadingConfig config) {
    final l10n = AppLocalizations.of(context);
    final attribute = config.attribute;
    if (attribute == Attribute.checked || attribute == Attribute.unchecked) {
      return Align(
        alignment: Alignment.topLeft,
        child: PnCheck(
          done: config.value,
          label: config.value ? l10n.markNotDone : l10n.markDone,
          onTap: () => config.onCheckboxTap(!config.value),
        ),
      );
    }
    if (attribute == Attribute.ul) {
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.fromLTRB(4, 9, 0, 0),
          decoration: const BoxDecoration(color: PnColors.terra, shape: BoxShape.circle),
        ),
      );
    }
    return null;
  }
}

/// Undo and redo only take back this user's own changes: the housemate's
/// (ChangeSource.remote) are not recorded, just shift what is recorded so
/// that it still applies where it should.
class _NoteDocument extends Document {
  _NoteDocument.fromDelta(super.delta) : super.fromDelta();

  final _history = History(userOnly: true);

  @override
  History get history => _history;
}

/// Copies the selection as Markdown, for other apps; [_NoteController]'s
/// paste reads it back.
class _NoteController extends QuillController {
  _NoteController({
    required super.document,
    required super.selection,
    required this.newId,
    required Future<bool> Function() onPaste,
  }) : super(
         // ignore: experimental_member_use, the only way to read what is pasted.
         config: QuillControllerConfig(clipboardConfig: QuillClipboardConfig(onClipboardPaste: onPaste)),
       );

  final String Function() newId;

  @override
  // ignore: experimental_member_use, the only way to change what is copied.
  bool clipboardSelection(bool copy) {
    final sel = selection;
    String? markdown;
    if (!sel.isCollapsed) {
      // The last line keeps its kind (bullet, heading…) even when its end
      // is not selected.
      final last = document.queryChild(sel.end).node;
      final slice = document.toDelta().slice(sel.start, sel.end);
      final endsLine = slice.isNotEmpty && slice.last.data is String && (slice.last.data! as String).endsWith('\n');
      if (!endsLine) slice.insert('\n', last is Line && last.style.isNotEmpty ? last.style.toJson() : null);
      markdown = blocksToMarkdown(deltaToBlocks(slice, const [], newId));
    }
    // ignore: experimental_member_use
    final done = super.clipboardSelection(copy);
    if (markdown != null && done) Clipboard.setData(ClipboardData(text: markdown));
    return done;
  }
}

/// This user's caret, blinking as Android's does.
class _Caret extends StatefulWidget {
  const _Caret({super.key});

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  Timer? _blink;
  bool _on = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _blink?.cancel();
    // Still when the phone asks for less motion (and in tests).
    if (!MediaQuery.disableAnimationsOf(context)) {
      _blink = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() => _on = !_on));
    }
  }

  @override
  void dispose() {
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(width: 2, color: _on ? PnColors.terra : Colors.transparent),
  );
}

/// The housemate's cursor while they type: a bar in their color, their
/// name above it.
class _RemoteCaret extends StatelessWidget {
  const _RemoteCaret(this.member);

  final Member member;

  @override
  Widget build(BuildContext context) {
    final color = Color(member.color);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -1, top: 0, bottom: 0, child: Container(width: 2, color: color)),
          Positioned(
            left: -1,
            top: -17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                member.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PnColors.snow, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
