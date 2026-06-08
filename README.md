# PICNOTE.

> Shared notes & tasks for two — real-time, with love.

A Flutter app for couples to manage their shared life: groceries, tasks, planning, and memos with a rich editor.

## Screens implemented

| Screen | File |
|---|---|
| Welcome / Auth landing | `lib/screens/welcome_screen.dart` |
| Email input | `lib/screens/email_screen.dart` |
| Password / Sign in | `lib/screens/password_screen.dart` |
| Home — Tasks & Memos | `lib/screens/home_screen.dart` |
| Add task sheet | `lib/screens/add_task_sheet.dart` |

## Design system

| Token | Light | Dark |
|---|---|---|
| Background | `#F5E6D3` (beige) | `#1A1208` (dark brown) |
| Card | `#FAEEE4` | `#2A1F10` |
| Primary | `#5C2D0A` | `#B07040` |
| Accent | `#8B4513` | `#8B4513` |

## Getting started

```bash
flutter pub get
flutter run
```

## Roadmap to real-time

1. **Auth** — Enable `firebase_auth` + `google_sign_in` in `pubspec.yaml`
2. **Real-time sync** — Replace `AppState` in-memory lists with Firestore streams:
   ```dart
   Stream<List<Task>> tasksStream() => FirebaseFirestore.instance
     .collection('tasks')
     .snapshots()
     .map((s) => s.docs.map(Task.fromDoc).toList());
   ```
3. **Rich editor** — Uncomment `flutter_quill` for memos with formatting
4. **Presence** — Use Firestore `updatedBy` field + real-time listener to show partner edits live
5. **Push notifications** — Firebase Messaging when partner adds/edits a task

## Architecture

```
lib/
├── main.dart              # App entry, theme, providers
├── theme/
│   └── app_theme.dart     # Colors, TextTheme, light/dark
├── models/
│   └── app_state.dart     # ChangeNotifier store (swap for Firestore)
├── screens/
│   ├── welcome_screen.dart
│   ├── email_screen.dart
│   ├── password_screen.dart
│   ├── home_screen.dart
│   └── add_task_sheet.dart
└── widgets/
    └── picnote_face.dart  # The cute mascot ʕ•ᴥ•ʔ
```
