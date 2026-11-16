import 'package:picnote/domain/models/household.dart';
import 'package:picnote/domain/models/task.dart';
import 'package:picnote/domain/models/task_list.dart';
import 'package:picnote/domain/models/user.dart';

const kMeUser = User(id: 'me', email: 'mel@picnote.cc', name: 'Mel');
const kMe = Member(id: 'me', name: 'Mel', color: 0xFFAF5C3C);
const kPartner = Member(id: 'yoann', name: 'Yoann', color: 0xFF3F7063);

const kDuo = Household(name: 'Maison', members: [kMe, kPartner]);
const kSolo = Household(name: 'Maison', members: [kMe]);

const kSharedList = TaskList(id: 'shared', name: 'Courses', isShared: true, pinned: true, color: ListColor.mustard);
const kPersonalList = TaskList(id: 'personal', name: 'Cadeaux', isShared: false, pinned: true);

/// 5 tasks on [kSharedList], 2 of them done.
const kSharedTasks = [
  Task(id: 't1', listId: 'shared', title: 'Tomates', byId: 'yoann'),
  Task(id: 't2', listId: 'shared', title: 'Café'),
  Task(id: 't3', listId: 'shared', title: 'Lait'),
  Task(id: 't4', listId: 'shared', title: 'Pain', done: true),
  Task(id: 't5', listId: 'shared', title: 'Huile', done: true),
];
