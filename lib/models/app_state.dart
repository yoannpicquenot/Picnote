import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskSection { today, tomorrow }

class Task {
  final String id;
  String title;
  bool completed;
  TaskSection section;
  String lastModifiedBy;
  DateTime lastModifiedAt;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    required this.section,
    required this.lastModifiedBy,
    required this.lastModifiedAt,
  });

  factory Task.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: d['title'] ?? '',
      completed: d['completed'] ?? false,
      section: d['section'] == 'today' ? TaskSection.today : TaskSection.tomorrow,
      lastModifiedBy: d['lastModifiedBy'] ?? '',
      lastModifiedAt: (d['lastModifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(lastModifiedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class Memo {
  final String id;
  String title;
  String content;
  String lastModifiedBy;
  DateTime lastModifiedAt;

  Memo({
    required this.id,
    required this.title,
    required this.content,
    required this.lastModifiedBy,
    required this.lastModifiedAt,
  });
}

class AppState extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  String currentUser = '';
  String partnerUser = '';
  String? _pairId;
  String? _currentUid;

  List<Task> tasks = [];
  List<Memo> memos = [];
  bool hasUnreadNote = false;
  String? partnerNotePreview;

  StreamSubscription? _tasksSub;
  StreamSubscription? _authSub;

  AppState() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadForUser(user);
      } else {
        _reset();
      }
    });
  }

  Future<void> _loadForUser(User user) async {
    if (_currentUid == user.uid) return; // already loaded
    _currentUid = user.uid;

    try {
      final userSnap = await _db.collection('users').doc(user.uid).get();
      final data = userSnap.data();
      if (data == null) return;

      currentUser = data['displayName'] ?? user.email ?? '';
      _pairId = data['pairId'] as String?;

      final partnerId = data['partnerId'] as String?;
      if (partnerId != null) {
        final partnerSnap = await _db.collection('users').doc(partnerId).get();
        partnerUser = partnerSnap.data()?['displayName'] ?? '';
      }

      if (_pairId != null) _listenToTasks();
      notifyListeners();
    } catch (_) {}
  }

  void _listenToTasks() {
    _tasksSub?.cancel();
    _tasksSub = _db
        .collection('pairs')
        .doc(_pairId)
        .collection('tasks')
        .orderBy('lastModifiedAt', descending: true)
        .snapshots()
        .listen((snap) {
      tasks = snap.docs.map(Task.fromDoc).toList();
      notifyListeners();
    });
  }

  void _reset() {
    _currentUid = null;
    _pairId = null;
    currentUser = '';
    partnerUser = '';
    tasks = [];
    _tasksSub?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> toggleTask(String id) async {
    if (_pairId == null) return;
    final task = tasks.firstWhere((t) => t.id == id);
    await _db
        .collection('pairs').doc(_pairId)
        .collection('tasks').doc(id)
        .update({
      'completed': !task.completed,
      'lastModifiedBy': currentUser,
      'lastModifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTask(String title, TaskSection section) async {
    if (_pairId == null) return;
    await _db
        .collection('pairs').doc(_pairId)
        .collection('tasks')
        .add({
      'title': title,
      'completed': false,
      'section': section.name,
      'lastModifiedBy': currentUser,
      'lastModifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String id) async {
    if (_pairId == null) return;
    await _db
        .collection('pairs').doc(_pairId)
        .collection('tasks').doc(id)
        .delete();
  }

  List<Task> get todayTasks =>
      tasks.where((t) => t.section == TaskSection.today).toList();

  List<Task> get tomorrowTasks =>
      tasks.where((t) => t.section == TaskSection.tomorrow).toList();

  void dismissNote() {
    hasUnreadNote = false;
    notifyListeners();
  }

  /// Call this after pairing so AppState picks up the new pairId without restart.
  Future<void> reload() async {
    _currentUid = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await _loadForUser(user);
  }
}
