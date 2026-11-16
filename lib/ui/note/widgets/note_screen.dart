import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/note.dart';
import '../../../domain/models/reminder.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/list_hero.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/item_menu.dart';
import '../../core/ui/item_sheets.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/list_sheet.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/sheet.dart';
import '../../core/ui/toast.dart';
import '../../invite/widgets/invite_sheet.dart';
import '../view_models/note_viewmodel.dart';
import 'block_menu.dart';
import 'format_bar.dart';
import 'note_editor.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key, required this.viewModel});

  final NoteViewModel viewModel;

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  late final _title = TextEditingController(text: widget.viewModel.note?.title ?? '');
  final _titleFocus = FocusNode();
  final _editor = GlobalKey<NoteEditorState>();
  final _bars = ValueNotifier<EditorBars>((format: false, slash: null));

  NoteViewModel get vm => widget.viewModel;

  /// Putting the app away counts as leaving the note.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: vm.release);
    vm.addListener(_syncTitle);
  }

  /// The housemate's title, as they type it or as saved, unless this user
  /// is typing it.
  void _syncTitle() {
    final title = vm.live?.title ?? vm.note?.title;
    if (_titleFocus.hasFocus || title == null || title == _title.text) return;
    _title.text = title;
  }

  @override
  void dispose() {
    vm.close();
    vm.removeListener(_syncTitle);
    _lifecycle.dispose();
    _titleFocus.dispose();
    _title.dispose();
    _bars.dispose();
    super.dispose();
  }

  Future<void> _askShare(Note note) async {
    final partner = vm.partner;
    if (partner == null) return;
    final l10n = AppLocalizations.of(context);
    final name = note.title.isEmpty ? l10n.untitled : note.title;
    final ok = await showPnSheet<bool>(
      context,
      ShareConfirmSheet(
        itemName: name,
        isList: false,
        makePersonal: note.isShared,
        partner: partner,
        members: vm.members,
      ),
    );
    if (ok != true) return;
    await vm.toggleShared();
    if (mounted) showToast(context, note.isShared ? l10n.nowPersonalNote : l10n.sharedWith(partner.name));
  }

  /// Deleted at once; the toast can bring it back.
  Future<void> _delete() async {
    final note = vm.note;
    if (note == null) return;
    final l10n = AppLocalizations.of(context);
    final deleted = await vm.delete();
    if (deleted == null || !mounted) return;
    showToast(
      context,
      l10n.noteDeleted(note.title.isEmpty ? l10n.untitled : note.title),
      onUndo: () => vm.restore(deleted),
    );
    await _back();
  }

  /// Latest changes, who sees it, delete. Only the author can make a
  /// shared note personal again, or delete it.
  Future<void> _menu() async {
    final note = vm.note;
    if (note == null) return;
    final l10n = AppLocalizations.of(context);
    final action = await showPnSheet<ItemMenuAction>(
      context,
      ItemMenuSheet(
        title: '${note.title.isEmpty ? l10n.untitled : note.title}.',
        isNote: true,
        changes: vm.latestChanges(),
        meId: vm.meId,
        members: vm.members,
        shared: note.isShared,
        theme: ListTheme.app,
        canShare: vm.canUnshareOrDelete,
        canDelete: vm.canUnshareOrDelete,
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ItemMenuAction.toggleShared:
        await _askShare(vm.note ?? note);
      case ItemMenuAction.invite:
        await showInviteSheet(context);
      case ItemMenuAction.delete:
        await _delete();
      case null:
        break;
    }
  }

  Future<void> _reminder() async {
    final note = vm.note;
    if (note == null) return;
    final result = await showPnSheet<(Reminder?,)>(
      context,
      ReminderSheet(
        initial: note.reminder,
        defaultTime: vm.defaultTime,
        theme: ListTheme.app,
        partnerName: note.isShared ? vm.partner?.name : null,
      ),
      editing: true,
    );
    if (result != null) await vm.setReminder(result.$1);
  }

  /// Back to the notes, once the keyboard is closed (see [closeKeyboard]).
  Future<void> _back() async {
    await closeKeyboard(context);
    if (mounted) context.go(Routes.notes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final note = vm.note;
        if (note == null) return const SizedBox.shrink();
        // Android back also waits for the keyboard to close first.
        return PopScope(
          canPop: MediaQuery.viewInsetsOf(context).bottom == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Stack(
            children: [
              // The note card grows into this page.
              Positioned.fill(
                child: NoteBackdrop(noteId: note.id, color: PnColors.cream),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // A window resized very short leaves no room at all.
                    minHeight: math.max(0, MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 4),
                  ),
                  child: ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: BackLink(label: l10n.tabNotes, onPressed: _back),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MenuDotsButton(
                              label: l10n.noteOptions,
                              color: PnColors.terraDark,
                              background: PnColors.peach,
                              onTap: _menu,
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.topLeft,
                          child: switch (vm.typist) {
                            final typist? => Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Avatar.of(typist, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.isTyping(typist.name),
                                    style: PnText.meta.copyWith(color: Color(typist.color)),
                                  ),
                                ],
                              ),
                            ),
                            null => const SizedBox(width: double.infinity),
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _title,
                          focusNode: _titleFocus,
                          autofocus: note.isBlank,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          style: PnText.screenTitle,
                          onChanged: vm.setTitle,
                          onSubmitted: (_) => _editor.currentState?.focusStart(),
                          decoration: InputDecoration.collapsed(
                            hintText: l10n.untitled,
                            hintStyle: PnText.screenTitle.copyWith(color: PnColors.terra.withValues(alpha: 0.35)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Pressable(
                            onTap: _reminder,
                            child: InfoPill(
                              text: note.reminder == null ? l10n.noReminder : reminderLabel(context, note.reminder!),
                              icon: PnIcons.bell,
                              color: PnColors.terraDark,
                              background: PnColors.peach,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        NoteEditor(key: _editor, viewModel: vm, blocks: note.blocks, bars: _bars),
                        const SizedBox(height: 24),
                        Text(l10n.slashHint, textAlign: TextAlign.center, style: PnText.meta),
                        SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
                      ],
                    ),
                  ),
                ),
              ),
              // On top of the keyboard (the page already ends there): the
              // formatting bar while text is selected, the "/" menu.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder(
                  valueListenable: _bars,
                  builder: (context, bars, _) {
                    final editor = _editor.currentState;
                    if (editor == null) return const SizedBox.shrink();
                    if (bars.slash case final query?) {
                      return BlockMenu(query: query, onPick: editor.pickBlock);
                    }
                    if (!bars.format) return const SizedBox.shrink();
                    return FormatBar(
                      selection: editor.controller,
                      isActive: editor.isActive,
                      onToggle: editor.toggleStyle,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
