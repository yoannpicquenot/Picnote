import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/household.dart';
import '../../../domain/models/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/controls.dart';
import '../../core/ui/date_fields.dart';
import '../../core/ui/edited_label.dart';
import '../../core/ui/home_header.dart';
import '../../core/ui/layout.dart';
import '../../core/ui/mascot.dart';
import '../../core/ui/list_hero.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/rise_in.dart';
import '../../invite/widgets/invite_sheet.dart';
import '../view_models/notes_viewmodel.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.viewModel});

  final NotesViewModel viewModel;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _wink = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = isDaytime();
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12, bottom: bottomBarClearance),
          child: ContentWidth(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: day ? -70 : -12,
                  top: day ? 18 : 34,
                  child: Watermark(winking: _wink),
                ),
                Gap(
                  gap: 20,
                  children: [
                    HomeHeader(
                      whoIsHere: vm.whoIsHere,
                      onInvite: () => showInviteSheet(context),
                      onSettings: () => context.go(Routes.settings),
                      onWordmark: () {
                        _timer?.cancel();
                        setState(() => _wink = true);
                        _timer = Timer(const Duration(milliseconds: 1500), () => setState(() => _wink = false));
                      },
                    ),
                    if (vm.notes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 72),
                        child: Column(
                          children: [
                            const Face(MascotMood.peek, height: 48),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noNotesYet,
                              textAlign: TextAlign.center,
                              style: PnText.sub.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Gap(
                        gap: 8,
                        children: [
                          Text(l10n.notesTitle, style: PnText.greeting),
                          Text(l10n.notesLede, style: PnText.lede),
                        ],
                      ),
                      _grid(context, vm),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, NotesViewModel vm) {
    final notes = vm.notes;
    // An odd count gives the first card the full width.
    return PairedGrid(
      firstWide: notes.length.isOdd,
      children: [
        for (final (i, n) in notes.indexed)
          RiseIn.staggered(
            index: i,
            child: _NoteCard(
              note: n,
              alt: i.isOdd,
              showPerso: !vm.isSolo,
              editor: vm.editor(n),
              onTap: () => context.go(Routes.note(n.id)),
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.alt,
    required this.showPerso,
    required this.editor,
    required this.onTap,
  });

  final Note note;
  final bool alt;
  final bool showPerso;
  final Member? editor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ink = PnColors.terraDark;
    final snippet = note.snippet;
    final reminder = note.reminder;
    final radius = BorderRadius.circular(24);
    return Pressable(
      onTap: onTap,
      child: Stack(
        // Passes the grid row's height on, so the date sits at the bottom.
        fit: StackFit.passthrough,
        children: [
          // Grows into the open note's page.
          Positioned.fill(
            child: NoteBackdrop(noteId: note.id, color: alt ? PnColors.snow : PnColors.peach, radius: radius),
          ),
          if (alt)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: PnColors.peachLine, width: 2),
                ),
              ),
            ),
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes have no icon, unlike lists.
                if (!note.isShared && showPerso) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: PersoMark(label: l10n.listPersonal, color: ink),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  '${note.title.isEmpty ? l10n.untitled : note.title}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PnText.cardTitle.copyWith(color: ink),
                ),
                if (snippet != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: ink),
                  ),
                ],
                const SizedBox(height: 10),
                const Spacer(),
                if (reminder != null) ...[
                  InfoPill(
                    text: dateLabel(context, effectiveDay(reminder.date)),
                    icon: PnIcons.bell,
                    color: ink,
                    background: alt ? PnColors.peach : PnColors.snow.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (editor != null) ...[Avatar.of(editor!, size: 18), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        editedLabel(context, note.editedAt),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
