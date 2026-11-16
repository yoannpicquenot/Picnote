import 'package:flutter/foundation.dart';

import '../../../domain/models/note.dart';
import '../../../utils/result.dart';

class DeletedNote {
  const DeletedNote({required this.note, required this.index});

  final Note note;
  final int index;
}

/// Source of truth for notes, most recently edited first.
abstract class NoteRepository extends ChangeNotifier {
  List<Note> get notes;

  Future<Result<void>> load();

  Future<Result<Note>> createNote({required String title, required bool isShared, required String authorId});

  Future<Result<void>> updateNote(Note note);

  /// Sends the edits still waiting to be saved.
  Future<void> flush();

  Future<Result<DeletedNote>> deleteNote(String id);

  Future<Result<void>> restoreNote(DeletedNote deleted);

  /// Joining a household keeps everything, as personal.
  Future<Result<void>> makeAllPersonal();
}
