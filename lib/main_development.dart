import 'config/local.dart';
import 'main.dart';

/// No backend: signed in as Mel with the design board's demo data, kept in
/// memory, skipping onboarding.
void main() => runPicnote(demoRepositories(), splash: false);
