import '../data/repositories/activity/activity_repository_local.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/household/household_repository_local.dart';
import '../data/repositories/invite_prompt/invite_prompt_repository.dart';
import '../data/repositories/list/list_repository_local.dart';
import '../data/repositories/live/live_repository.dart';
import '../data/repositories/memo/memo_repository_local.dart';
import '../data/repositories/note/note_repository_local.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../domain/models/activity.dart';
import '../domain/models/household.dart';
import '../domain/models/memo_task.dart';
import '../domain/models/note.dart';
import '../domain/models/reminder.dart';
import '../domain/models/task.dart';
import '../domain/models/task_list.dart';
import '../domain/models/user.dart';
import '../utils/dates.dart';
import 'dependencies.dart';

/// Empty, signed-out, in-memory repositories.
Repositories localRepositories() => Repositories(
  auth: AuthRepositoryLocal(),
  household: HouseholdRepositoryLocal(),
  lists: ListRepositoryLocal(),
  memos: MemoRepositoryLocal(),
  notes: NoteRepositoryLocal(),
  settings: SettingsRepositoryLocal(),
  activity: ActivityRepositoryLocal(),
  live: LiveRepositoryLocal(),
  invitePrompt: InvitePromptRepositoryLocal(),
);

/// Mel, signed in, sharing "Maison Saint-Rambert" with Yoann, with the demo
/// lists and notes of the design board.
Repositories demoRepositories({bool french = true}) {
  String l(String en, String fr) => french ? fr : en;
  const me = Member(id: 'me', name: 'Mel', color: 0xFFAF5C3C);
  final yoann = HouseholdRepositoryLocal.partner;
  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
  return Repositories(
    auth: AuthRepositoryLocal(
      user: const User(id: 'me', email: 'mel@picnote.cc', name: 'Mel', color: 0xFFAF5C3C),
    ),
    household: HouseholdRepositoryLocal(
      household: Household(name: 'Maison Saint-Rambert', members: [me, yoann]),
    ),
    settings: SettingsRepositoryLocal(),
    memos: MemoRepositoryLocal(
      tasks: [
        MemoTask(
          id: 'pb1',
          title: l('Take out the bins', 'Sortir les poubelles'),
          forId: yoann.id,
          remindOn: nextWeekday(DateTime.tuesday),
          remindHour: 20,
          repeat: MemoRepeat.weekly,
          authorId: 'me',
        ),
        MemoTask(
          id: 'pb2',
          title: l('Book the vet for Pistache', 'Prendre RDV véto pour Pistache'),
          forId: 'me',
          remindOn: inDays(1),
          remindHour: 9,
          authorId: 'me',
        ),
        MemoTask(
          id: 'pb3',
          title: l('Water the plants', 'Arroser les plantes'),
          forBoth: true,
          remindOn: today(),
          remindHour: 18,
          repeat: MemoRepeat.weekly,
          authorId: yoann.id,
        ),
        MemoTask(id: 'pb4', title: l('Call the plumber', 'Appeler le plombier'), forId: 'me', authorId: 'me'),
        MemoTask(id: 'pb5', title: l('Buy light bulbs', 'Acheter des ampoules'), authorId: yoann.id),
      ],
    ),
    live: LiveRepositoryLocal(),
    invitePrompt: InvitePromptRepositoryLocal(),
    activity: ActivityRepositoryLocal(
      online: {'me', yoann.id},
      entries: [
        Activity(
          isNote: false,
          itemId: 'd',
          actorId: yoann.id,
          verb: ActivityVerb.add,
          item: l('Chill the wine', 'Mettre le vin au frais'),
          at: ago(45),
        ),
        Activity(
          isNote: false,
          itemId: 'c',
          actorId: yoann.id,
          verb: ActivityVerb.add,
          item: l('Coffee', 'Café'),
          at: ago(120),
        ),
        Activity(isNote: true, itemId: 'ca', actorId: yoann.id, verb: ActivityVerb.edit, at: ago(125)),
        Activity(
          isNote: false,
          itemId: 'm',
          actorId: yoann.id,
          verb: ActivityVerb.check,
          item: l('Fix the shelf', 'Réparer l’étagère'),
          at: ago(180),
        ),
        Activity(
          isNote: false,
          itemId: 'c',
          actorId: 'me',
          verb: ActivityVerb.add,
          item: l('Croissants + milk', 'Croissants + lait'),
          at: ago(300),
        ),
        Activity(isNote: true, itemId: 'mo', actorId: 'me', verb: ActivityVerb.edit, at: ago(1440)),
        Activity(
          isNote: false,
          itemId: 'c',
          actorId: yoann.id,
          verb: ActivityVerb.add,
          item: l('Tomatoes', 'Tomates'),
          at: ago(1500),
        ),
        Activity(
          isNote: false,
          itemId: 'm',
          actorId: 'me',
          verb: ActivityVerb.check,
          item: l('Do the laundry', 'Faire la lessive'),
          at: ago(1560),
        ),
        Activity(isNote: false, itemId: 'b', actorId: 'me', verb: ActivityVerb.check, item: 'Sapiens', at: ago(2900)),
        Activity(isNote: false, itemId: 'm', actorId: 'me', verb: ActivityVerb.create, at: ago(9000)),
        Activity(isNote: false, itemId: 'c', actorId: 'me', verb: ActivityVerb.create, at: ago(9100)),
      ],
    ),
    lists: ListRepositoryLocal(
      lists: [
        TaskList(
          id: 'c',
          pinned: true,
          name: l('Groceries', 'Courses'),
          color: ListColor.mustard,
          icon: ListIcon.shoppingCart,
          isShared: true,
          day: inDays(0),
          reminder: Reminder(date: inDays(0), time: '10:00'),
        ),
        TaskList(
          id: 'm',
          pinned: true,
          name: l('House', 'Maison'),
          color: ListColor.sage,
          icon: ListIcon.house,
          isShared: true,
        ),
        TaskList(
          id: 'd',
          pinned: true,
          name: l('Dinner party', 'Dîner'),
          color: ListColor.cocoa,
          icon: ListIcon.gift,
          isShared: true,
          day: inDays(1),
          reminder: Reminder(date: inDays(1), time: '18:00'),
        ),
        TaskList(
          id: 'l',
          pinned: true,
          name: l('Lisbon trip', 'Lisbonne'),
          color: ListColor.peach,
          icon: ListIcon.paperPlane,
          isShared: true,
          day: inDays(12),
          reminder: Reminder(date: inDays(10), time: '9:00'),
        ),
        TaskList(id: 'b', name: l('Books', 'Livres'), color: ListColor.rose, icon: ListIcon.book),
        TaskList(id: 'g', name: l('Garden', 'Jardin'), color: ListColor.sage, icon: ListIcon.leaf, isShared: true),
        TaskList(id: 'w', name: l('Weekend', 'Week-end'), color: ListColor.mustard, icon: ListIcon.sun, isShared: true),
        TaskList(
          id: 'h',
          name: l('Mum’s birthday', 'Anniv de maman'),
          color: ListColor.rose,
          icon: ListIcon.heart,
          day: inDays(20),
          reminder: Reminder(date: inDays(18), time: '9:00'),
        ),
      ],
      tasks: [
        Task(id: '1', listId: 'c', title: l('Croissants + milk', 'Croissants + lait'), byId: 'me'),
        Task(id: '2', listId: 'c', title: l('Tomatoes', 'Tomates'), byId: 'yoann'),
        Task(id: '3', listId: 'c', title: l('Coffee', 'Café'), byId: 'yoann'),
        Task(id: '4', listId: 'c', title: l('Olive oil', 'Huile d’olive')),
        Task(id: '5', listId: 'm', title: l('Water plants', 'Arroser les plantes'), today: true),
        Task(id: '6', listId: 'm', title: l('Fix the shelf', 'Réparer l’étagère'), done: true, byId: 'yoann'),
        Task(id: '7', listId: 'm', title: l('Do the laundry', 'Faire la lessive'), done: true, byId: 'me'),
        Task(id: '8', listId: 'm', title: l('Clean windows', 'Laver les vitres')),
        Task(id: '9', listId: 'm', title: l('Change bulbs', 'Changer les ampoules')),
        Task(id: '10', listId: 'm', title: l('Recycling', 'Sortir le recyclage')),
        Task(id: '11', listId: 'l', title: l('Book the flat', 'Réserver l’appart')),
        Task(id: '12', listId: 'd', title: l('Buy flowers', 'Acheter des fleurs')),
        Task(id: '13', listId: 'd', title: l('Chill the wine', 'Mettre le vin au frais'), byId: 'yoann'),
        Task(id: '14', listId: 'b', title: 'Sapiens', done: true),
        Task(id: '15', listId: 'b', title: l('The Overstory', 'L’Arbre-monde')),
        Task(id: '16', listId: 'g', title: l('Plant basil', 'Planter du basilic')),
        Task(id: '17', listId: 'h', title: l('Find a gift', 'Trouver un cadeau')),
        Task(id: '18', listId: 'w', title: l('Cat litter', 'Litière du chat')),
        Task(id: '19', listId: 'w', title: l('Take the bins out', 'Sortir les poubelles')),
        Task(id: '20', listId: 'w', title: l('Repot the ficus', 'Rempoter le ficus')),
      ],
    ),
    notes: NoteRepositoryLocal(
      notes: [
        Note(
          id: 'ca',
          title: l('Canada trip', 'Voyage au Canada'),
          authorId: 'yoann',
          editedById: 'yoann',
          editedAt: now.subtract(const Duration(hours: 2)),
          isShared: true,
          reminder: Reminder(date: inDays(3), time: '9:00'),
          blocks: [
            NoteBlock(
              id: 'b1',
              text: l(
                'Two weeks in September. Montréal first, then the Gaspé coast by car.',
                'Deux semaines en septembre. Montréal d’abord, puis la Gaspésie en voiture.',
              ),
            ),
            NoteBlock(id: 'b2', type: NoteBlockType.heading, text: l('Places to visit', 'Lieux à visiter')),
            NoteBlock(id: 'b3', type: NoteBlockType.bullet, text: l('Old Montréal', 'Le Vieux-Montréal')),
            const NoteBlock(id: 'b4', type: NoteBlockType.bullet, text: 'Parc de la Gaspésie'),
            NoteBlock(id: 'b5', type: NoteBlockType.bullet, text: l('Percé Rock', 'Le rocher Percé')),
            NoteBlock(id: 'b6', type: NoteBlockType.heading, text: l('To pack', 'À préparer')),
            NoteBlock(id: 'b7', type: NoteBlockType.todo, text: l('Passports', 'Passeports'), done: true),
            NoteBlock(id: 'b8', type: NoteBlockType.todo, text: l('Rain jackets', 'Vestes de pluie')),
            NoteBlock(id: 'b9', type: NoteBlockType.todo, text: l('Plug adapter', 'Adaptateur de prise')),
            const NoteBlock(id: 'b10', type: NoteBlockType.link, text: 'airbnb.com/rooms/montreal-plateau'),
          ],
        ),
        Note(
          id: 'mo',
          title: l('Moto papers', 'Papiers moto'),
          authorId: 'me',
          editedById: 'me',
          editedAt: now.subtract(const Duration(days: 1)),
          reminder: Reminder(date: nextMonth, time: '9:00'),
          blocks: [
            NoteBlock(
              id: 'c1',
              text: l('Everything to check on the 1st of the month.', 'Tout ce qu’il faut vérifier le 1er du mois.'),
            ),
            NoteBlock(id: 'c2', type: NoteBlockType.todo, text: l('Insurance certificate', 'Attestation d’assurance')),
            NoteBlock(id: 'c3', type: NoteBlockType.todo, text: l('Technical inspection', 'Contrôle technique')),
          ],
        ),
      ],
    ),
  );
}
