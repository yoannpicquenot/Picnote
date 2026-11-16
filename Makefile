# Picnote commands. The Supabase build reads its settings from env.json
# (see env.example.json).

ENV := --dart-define-from-file=env.json

.PHONY: run run-demo apk appbundle ipa test analyze l10n

## Run against Supabase on a device or emulator
run:
	flutter run $(ENV)

## Run with the in-memory demo data (no backend)
run-demo:
	flutter run -t lib/main_development.dart

## Android APK
apk:
	flutter build apk --release $(ENV)

## Android App Bundle, for the Play Store
appbundle:
	flutter build appbundle --release $(ENV)

## iOS archive, for the App Store (macOS only)
ipa:
	flutter build ipa --release $(ENV)

test:
	flutter test

analyze:
	flutter analyze

## Regenerate translations after editing lib/l10n/*.arb
l10n:
	flutter gen-l10n
