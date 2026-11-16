[Folders architecture]
lib/
├── ui/
│   ├── core/
│   │   ├── ui/              # shared widgets
│   │   └── themes/
│   └── <feature>/           # one folder per feature (screen)
│       ├── view_models/     # <feature>_viewmodel.dart (ChangeNotifier)
│       └── widgets/         # <feature>_screen.dart + feature-specific widgets
├── domain/
│   └── models/              # app-wide data types used by both ui and data
├── data/
│   ├── repositories/        # source of truth, shared across features
│   ├── services/            # wrap external APIs (HTTP, local DB, platform)
│   └── model/               # raw API/DB models, kept separate from domain models
├── config/                  # dependency wiring per environment
├── routing/                 # router + route names
├── utils/                   # helpers (e.g. Result, Command)
├── main.dart
├── main_development.dart
└── main_staging.dart

test/      # mirrors lib/: data/, domain/, ui/, utils/
testing/   # fakes + test fixtures, not shipped
