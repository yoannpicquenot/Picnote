import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/controls.dart';
import '../view_models/note_viewmodel.dart';
import 'format_bar.dart';
import 'note_delta.dart';

/// What the screen shows above the keyboard: the formatting bar while text
/// is selected, the block menu while a line starts with "/".
typedef EditorBars = ({bool format, String? slash});

/// The body of a note, one document so that a selection can span lines.
/// Each line is a block: text, heading, bullet or checkbox. Enter keeps a
/// list going, Enter on an empty item ends it, and "/" at the start of a
/// line opens the block menu.
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
  late final controller = QuillController(
    document: Document.fromDelta(blocksToDelta(widget.blocks)),
    selection: const TextSelection.collapsed(offset: 0),
  );
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final StreamSubscription<DocChange> _changes;

  NoteViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _changes = controller.changes.listen((change) {
      if (change.source == ChangeSource.local) _save();
    });
    controller.addListener(_updateBars);
    _focus.addListener(_updateBars);
  }

  @override
  void didUpdateWidget(NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Someone else's change, unless the note is being typed in: as they
    // type it, or else as saved.
    WidgetsBinding.instance.addPostFrameCallback((_) => _placeCaret());
    if (_focus.hasFocus) return;
    final blocks = vm.live?.blocks ?? widget.blocks;
    if (!sameBlocks(_blocks(), blocks)) controller.document = Document.fromDelta(blocksToDelta(blocks));
  }

  final _quill = GlobalKey<QuillEditorState>();
  final _stack = GlobalKey();

  /// The housemate's cursor, in this widget, while they type.
  Rect? _caret;

  void _placeCaret() {
    if (!mounted) return;
    final offset = _focus.hasFocus ? null : vm.live?.cursor;
    final editor = _quill.currentState?.editableTextKey.currentState?.renderEditor;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    Rect? caret;
    if (offset != null && editor != null && editor.attached && stack != null) {
      final rect = editor.getLocalRectForCaret(TextPosition(offset: offset.clamp(0, controller.document.length - 1)));
      caret = stack.globalToLocal(editor.localToGlobal(rect.topLeft)) & rect.size;
    }
    if (caret != _caret) setState(() => _caret = caret);
  }

  @override
  void dispose() {
    _changes.cancel();
    controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<NoteBlock> _blocks() => deltaToBlocks(controller.document.toDelta(), widget.blocks, vm.newBlockId);

  void _save() => vm.setBlocks(_blocks(), cursor: controller.selection.extentOffset);

  Line? get _line {
    final node = controller.document.queryChild(controller.selection.baseOffset).node;
    return node is Line ? node : null;
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

  /// From the title's Enter.
  void focusStart() {
    _focus.requestFocus();
    controller.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);
  }

  /// From the formatting bar: applies to the selection.
  void toggleStyle(InlineStyle style) {
    final attribute = switch (style) {
      InlineStyle.bold => Attribute.bold,
      InlineStyle.italic => Attribute.italic,
      InlineStyle.underline => Attribute.underline,
    };
    final on = controller.getSelectionStyle().attributes.containsKey(attribute.key);
    controller.formatSelection(on ? Attribute.clone(attribute, null) : attribute);
  }

  bool isActive(InlineStyle style) => controller.getSelectionStyle().attributes.containsKey(switch (style) {
    InlineStyle.bold => Attribute.bold.key,
    InlineStyle.italic => Attribute.italic.key,
    InlineStyle.underline => Attribute.underline.key,
  });

  /// From the "/" menu: the "/…" typed goes, the line takes [type], and
  /// typing goes on in it.
  void pickBlock(NoteBlockType type) {
    final line = _line;
    if (line == null) return;
    final start = line.documentOffset;
    controller.replaceText(start, line.length - 1, '', TextSelection.collapsed(offset: start));
    for (final attribute in lineAttributes(type)) {
      controller.formatText(start, 0, attribute);
    }
    _focus.requestFocus();
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          key: _stack,
          clipBehavior: Clip.none,
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
                customStyles: DefaultStyles(
                  paragraph: const DefaultTextBlockStyle(base, flat, lineGap, none, null),
                  placeHolder: DefaultTextBlockStyle(
                    base.copyWith(color: PnColors.placeholder),
                    flat,
                    lineGap,
                    none,
                    null,
                  ),
                  h1: const DefaultTextBlockStyle(
                    TextStyle(
                      fontFamily: PnFonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      height: 1.2,
                      color: PnColors.terra,
                    ),
                    flat,
                    VerticalSpacing(12, 6),
                    none,
                    null,
                  ),
                  lists: DefaultListBlockStyle(
                    base,
                    flat,
                    lineGap,
                    lineGap,
                    null,
                    null,
                    indentWidthBuilder: (block, context, count, numberPointWidth) => const HorizontalSpacing(40, 0),
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
            if ((_caret, vm.typist) case (final caret?, final typist?))
              Positioned.fromRect(rect: caret, child: _RemoteCaret(typist)),
          ],
        ),
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapTail, child: const SizedBox(height: 80)),
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
            bottom: '\n'.isEmpty ? 0 : null,
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
