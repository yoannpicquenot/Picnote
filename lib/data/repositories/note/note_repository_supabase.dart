import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/note.dart';
import '../../../utils/result.dart';
import '../../model/rows.dart';
import '../synced_repository.dart';
import 'note_repository.dart';

/// Notes from Supabase, kept live. Typing saves after a short pause rather
/// than on every keystroke.
class NoteRepositorySupabase extends NoteRepository with SyncedRepository {
  NoteRepositorySupabase(this.client, {this.saveDelay = const Duration(milliseconds: 600)});

  @override
  final SupabaseClient client;

  final Duration saveDelay;

  static const _uuid = Uuid();

  List<Note> _notes = [];

  /// Notes edited locally and not sent yet, with whether they were shared
  /// before the first unsent edit.
  final Map<String, ({Timer timer, int write, bool wasShared})> _unsaved = {};

  @override
  List<Note> get notes => List.unmodifiable([..._notes]..sort((a, b) => b.editedAt.compareTo(a.editedAt)));

  @override
  List<String> get watchedTables => const ['notes'];

  @override
  void clear() {
    for (final pending in _unsaved.values) {
      pending.timer.cancel();
    }
    _unsaved.clear();
    _notes = [];
  }

  @override
  Future<void Function()> fetch() async {
    final rows = await client.from('notes').select();
    return () => _notes = [for (final r in rows) noteFromRow(r)];
  }

  @override
  Future<Result<void>> load() => ensureLoaded();

  @override
  Future<Result<Note>> createNote({required String title, required bool isShared, required String authorId}) async {
    final note = Note(
      id: _uuid.v4(),
      title: title,
      isShared: isShared,
      authorId: authorId,
      editedById: authorId,
      editedAt: DateTime.now(),
      blocks: [NoteBlock(id: _uuid.v4())],
    );
    _notes.add(note);
    final result = await push(() => client.from('notes').insert({...noteToRow(note), 'author_id': authorId}));
    return switch (result) {
      Ok() => Result.ok(note),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> updateNote(Note note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i < 0) return Result.error(Exception('Unknown note ${note.id}'));
    final previous = _unsaved.remove(note.id);
    previous?.timer.cancel();
    final write = previous?.write ?? beginWrite();
    final wasShared = previous?.wasShared ?? _notes[i].isShared;
    _notes[i] = note;
    _unsaved[note.id] = (timer: Timer(saveDelay, () => _save(note.id)), write: write, wasShared: wasShared);
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _save(String id) {
    final pending = _unsaved.remove(id);
    if (pending == null) return Future.value(const Result.ok(null));
    final note = _notes.where((n) => n.id == id).firstOrNull;
    return endWrite(
      pending.write,
      () async {
        if (note != null) await client.from('notes').update(noteToRow(note)).eq('id', id);
      },
      // The other member gets no event for a row they can no longer see.
      ping: note != null && pending.wasShared && !note.isShared,
    );
  }

  @override
  Future<void> flush() => Future.wait(
    [..._unsaved.keys].map((id) {
      _unsaved[id]!.timer.cancel();
      return _save(id);
    }),
  );

  @override
  Future<Result<DeletedNote>> deleteNote(String id) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i < 0) return Result.error(Exception('Unknown note $id'));
    final pending = _unsaved.remove(id);
    if (pending != null) {
      pending.timer.cancel();
      await endWrite(pending.write, () async {});
    }
    final deleted = DeletedNote(note: _notes.removeAt(i), index: i);
    final result = await push(() => client.from('notes').delete().eq('id', id));
    return switch (result) {
      Ok() => Result.ok(deleted),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> restoreNote(DeletedNote deleted) async {
    final note = deleted.note;
    _notes.insert(deleted.index.clamp(0, _notes.length), note);
    final author = note.authorId.isEmpty ? null : note.authorId;
    return push(() => client.from('notes').insert({...noteToRow(note), 'author_id': ?author}));
  }

  /// Personal notes stay personal when joining a household; there is
  /// nothing to change on the server.
  @override
  Future<Result<void>> makeAllPersonal() => refresh();

  @override
  void dispose() {
    flush();
    super.dispose();
  }
}
