import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/live.dart';
import '../../../domain/models/note.dart';

/// What the housemates are typing right now, keystroke by keystroke, and
/// what this user types, sent to them. Nothing here is saved: the lists
/// and notes repositories do that.
///
/// What someone typed is dropped after [quiet] without news from them:
/// they stopped, and the saved version has caught up by then.
abstract class LiveRepository extends ChangeNotifier {
  LiveRepository({this.quiet = const Duration(seconds: 3)});

  final Duration quiet;

  final Map<String, (LiveNote, Timer)> _notes = {};
  final Map<String, (LiveDraft, Timer)> _drafts = {};

  /// Note [id] as a housemate is typing it, if they are.
  LiveNote? note(String id) => _notes[id]?.$1;

  /// The item a housemate is typing into list [listId], if they are.
  LiveDraft? draft(String listId) => _drafts[listId]?.$1;

  /// Sends note [id] as this user has it now.
  void typeNote(String id, {required String title, required List<NoteBlock> blocks, int? cursor});

  /// Sends the item this user is typing into list [listId]; empty when
  /// they stop (added it, or cleared it).
  void typeDraft(String listId, String text);

  /// For the implementations: a housemate's keystroke arrived.
  @protected
  void receiveNote(String id, LiveNote note) {
    _notes[id]?.$2.cancel();
    _notes[id] = (note, Timer(quiet, () => _drop(_notes, id)));
    notifyListeners();
  }

  @protected
  void receiveDraft(String listId, LiveDraft draft) {
    _drafts.remove(listId)?.$2.cancel();
    if (draft.text.isNotEmpty) _drafts[listId] = (draft, Timer(quiet, () => _drop(_drafts, listId)));
    notifyListeners();
  }

  /// For the implementations: signed out, or another household.
  @protected
  void forgetAll() {
    _cancelAll();
    notifyListeners();
  }

  void _drop(Map<String, (Object, Timer)> entries, String key) {
    if (entries.remove(key) != null) notifyListeners();
  }

  void _cancelAll() {
    for (final (_, timer) in [..._notes.values, ..._drafts.values]) {
      timer.cancel();
    }
    _notes.clear();
    _drafts.clear();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}

/// Alone: nothing is sent. Tests feed it housemates' typing with
/// [receiveNote] and [receiveDraft], and read what was sent in [sent].
class LiveRepositoryLocal extends LiveRepository {
  LiveRepositoryLocal({super.quiet});

  /// What [typeNote] and [typeDraft] were called with, in order.
  final sent = <Object>[];

  @override
  void typeNote(String id, {required String title, required List<NoteBlock> blocks, int? cursor}) =>
      sent.add(LiveNote(userId: 'me', title: title, blocks: blocks, cursor: cursor));

  @override
  void typeDraft(String listId, String text) => sent.add(LiveDraft(userId: 'me', text: text));

  // Public here, for tests.
  @override
  // ignore: unnecessary_overrides
  void receiveNote(String id, LiveNote note) => super.receiveNote(id, note);

  @override
  // ignore: unnecessary_overrides
  void receiveDraft(String listId, LiveDraft draft) => super.receiveDraft(listId, draft);
}
