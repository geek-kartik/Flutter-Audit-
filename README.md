# flutter_audit

A modular, extensible, and completely offline Dart CLI tool that scans Flutter projects to generate comprehensive project audit reports.

## Features

- 📦 **Unused Dependencies**: Scans `pubspec.yaml` and source imports to flag unused packages.
- 🎨 **Unused & Duplicate Assets**: Computes SHA256 hashes to find duplicate assets and AST analysis to detect unused images/icons/fonts.
- 🐘 **Large Assets & Performance**: Identifies oversized images, vector SVGs, JSON/Lottie files, and heavy font families.
- 🪪 **License Compliance**: Checks for a project LICENSE file and scans pub cache for dependency license declarations.
- 📈 **Flutter Upgrade Suggestions**: Detects current Flutter SDK version, channel, and SDK constraint; flags non-stable channels and outdated versions.
- 📁 **Directory & Pubspec Hygiene**: Identifies empty folders, duplicate filenames, temporary files (`.DS_Store`), backup files, and broken pubspec asset/font paths.
- 💯 **Project Health Score**: Calculates a weighted score out of 100 using diminishing returns so scores never bottom out at zero.
- 📄 **Multiple Report Formats**: Supports interactive colored terminal output, JSON export, and Markdown report generation (`audit_report.md`).
- 🔒 **100% Offline**: Requires zero internet APIs, cloud calls, pub.dev queries, or vulnerability lookup services.

## Installation

Activate globally or run using `dart run`:

```bash
dart pub global activate flutter_audit
```

Or run directly from source:

```bash
dart run bin/flutter_audit.dart
```

## CLI Usage

### Audit Complete Project
Run all analyzers on the current directory:
```bash
flutter_audit audit
```
Or target a specific Flutter project directory:
```bash
flutter_audit audit --path /path/to/flutter_project
```

### Subcommands

```bash
# Scan assets only
flutter_audit assets

# Scan dependencies only
flutter_audit dependencies

# Scan performance bottlenecks only
flutter_audit performance
```

### Report Formats & Output

```bash
# Generate JSON output
flutter_audit audit --json

# Generate Markdown report (audit_report.md)
flutter_audit audit --markdown

# Output report to custom file path
flutter_audit audit --json --output build/audit.json
```

## Architecture & Extensibility

`flutter_audit` is designed according to SOLID principles. Custom analyzers can be added by implementing the `Analyzer` abstract contract:

```dart
abstract class Analyzer {
  Future<List<Issue>> analyze(Project project);
}
```

### Package Structure

```
flutter_audit/
├── bin/
│   └── flutter_audit.dart
├── lib/
│   ├── analyzers/
│   │   ├── base_analyzer.dart
│   │   ├── dependency_analyzer.dart
│   │   ├── asset_analyzer.dart
│   │   ├── license_analyzer.dart
│   │   ├── flutter_upgrade_analyzer.dart
│   │   ├── performance_analyzer.dart
│   │   ├── directory_analyzer.dart
│   │   └── pubspec_analyzer.dart
│   ├── commands/
│   │   ├── base_command.dart
│   │   ├── audit_command.dart
│   │   ├── assets_command.dart
│   │   ├── dependencies_command.dart
│   │   └── performance_command.dart
│   ├── models/
│   │   ├── project.dart
│   │   ├── report.dart
│   │   ├── issue.dart
│   │   ├── severity.dart
│   │   ├── asset_info.dart
│   │   ├── dart_file_info.dart
│   │   ├── directory_info.dart
│   │   └── pubspec_info.dart
│   ├── reporters/
│   │   ├── console_reporter.dart
│   │   ├── json_reporter.dart
│   │   └── markdown_reporter.dart
│   ├── scanners/
│   │   ├── pubspec_scanner.dart
│   │   ├── import_scanner.dart
│   │   ├── asset_scanner.dart
│   │   ├── dart_file_scanner.dart
│   │   └── directory_scanner.dart
│   └── utils/
│       ├── config.dart
│       ├── extensions.dart
│       └── logger.dart
└── test/
```

## License

MIT
