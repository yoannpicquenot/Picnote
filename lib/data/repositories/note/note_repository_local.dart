import '../../../domain/models/note.dart';
import '../../../utils/result.dart';
import 'note_repository.dart';

/// In-memory implementation used until the Supabase repository exists.
class NoteRepositoryLocal extends NoteRepository {
  NoteRepositoryLocal({List<Note> notes = const []}) : _notes = [...notes];

  final List<Note> _notes;
  int _nextId = 0;

  @override
  List<Note> get notes => List.unmodifiable([..._notes]..sort((a, b) => b.editedAt.compareTo(a.editedAt)));

  @override
  Future<Result<void>> load() async => const Result.ok(null);

  @override
  Future<Result<Note>> createNote({required String title, required bool isShared, required String authorId}) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final note = Note(
      id: 'n$stamp-${_nextId++}',
      title: title,
      isShared: isShared,
      authorId: authorId,
      editedById: authorId,
      editedAt: DateTime.now(),
      blocks: [NoteBlock(id: 'b$stamp')],
    );
    _notes.add(note);
    notifyListeners();
    return Result.ok(note);
  }

  @override
  Future<Result<void>> updateNote(Note note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i < 0) return Result.error(Exception('Unknown note ${note.id}'));
    _notes[i] = note;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<DeletedNote>> deleteNote(String id) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i < 0) return Result.error(Exception('Unknown note $id'));
    final deleted = DeletedNote(note: _notes.removeAt(i), index: i);
    notifyListeners();
    return Result.ok(deleted);
  }

  @override
  Future<Result<void>> restoreNote(DeletedNote deleted) async {
    _notes.insert(deleted.index.clamp(0, _notes.length), deleted.note);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> makeAllPersonal() async {
    for (var i = 0; i < _notes.length; i++) {
      _notes[i] = _notes[i].copyWith(isShared: false);
    }
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<void> flush() async {}
}
