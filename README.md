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

## Prerequisites

- **Dart SDK 3.0+** (bundled with Flutter) — verify with `dart --version`
- **Flutter** (recommended) — verify with `flutter --version`

## 👤 For Users

### Installation

The package must be reachable from your machine. Choose one option:

**Option A — activate directly from git** (recommended; no publishing required):

```bash
dart pub global activate --source git https://github.com/geek-kartik/Flutter-Audit-.git
```

**Option B — clone and activate locally**:

```bash
git clone https://github.com/geek-kartik/Flutter-Audit-.git
cd Flutter-Audit-
dart pub global activate --source path .
```

**Option C — from pub.dev** (once the package is published):

```bash
dart pub global activate flutter_audit
```

### CLI Usage

#### Check the installed version

```bash
flutter_audit --version
# → flutter_audit 1.0.0
```

#### Audit Complete Project

Run all analyzers on the current directory. This also generates `audit_report.md` in the project root with a timestamp refreshed on every run:

```bash
flutter_audit audit
```

Or target a specific Flutter project directory:

```bash
flutter_audit audit --path /path/to/flutter_project
```

#### Category Flags

`flutter_audit audit` accepts flags to scope the audit to specific categories. Combine flags to run multiple categories at once:

| Flag | Category |
| --- | --- |
| `--dependencies` | Unused dependencies |
| `--assets` | Unused/duplicate assets |
| `--architecture` | Unreachable files, huge widgets/classes |
| `--performance` | Large assets, deep widget trees |
| `--directory` | Directory hygiene |
| `--pubspec` | Pubspec hygiene |
| `--licenses` | License compliance |
| `--flutter` | Flutter upgrade suggestions |

#### Subcommands

```bash
# Scan assets only
flutter_audit assets

# Scan dependencies only
flutter_audit dependencies

# Scan performance bottlenecks only
flutter_audit performance
```

#### Report Formats & Output

```bash
# Generate JSON output
flutter_audit audit --json

# Generate Markdown report (audit_report.md) with a timestamp
flutter_audit audit --markdown

# Output report to custom file path
flutter_audit audit --json --output build/audit.json
```

Notes on generated files:
- `flutter_audit audit` always writes an `audit_report.md` with a `Generated at` timestamp reflecting when the report was last updated.
- `flutter_audit audit --markdown` writes a Markdown report (with audit timestamp) to `audit_report.md` by default.
- `flutter_audit performance` only creates `performance_audit.csv` when performance issues are found (skipped when the audit is clean).

## 👨‍💻 For Developers

### Getting Started

Clone the repository and install dependencies:

```bash
git clone https://github.com/geek-kartik/Flutter-Audit-.git
cd Flutter-Audit-
dart pub get
```

Run the CLI from source:

```bash
dart run bin/flutter_audit.dart audit
dart run bin/flutter_audit.dart audit --performance
```

Run the test suite:

```bash
dart test
```

Run static analysis:

```bash
dart analyze
```

### Architecture & Extensibility

`flutter_audit` is designed according to SOLID principles. Custom analyzers can be added by implementing the `Analyzer` abstract contract:

```dart
abstract class Analyzer {
  Future<List<Issue>> analyze(Project project);
}
```

### Contributing

Contributions are welcome! To get started:

1. **Fork** the repository and create a feature branch.
2. Make your changes, following the existing code style and adding tests where appropriate.
3. Run `dart analyze` and `dart test` to make sure everything passes.
4. Open a **pull request** describing your changes.

Areas that benefit from contributions: new analyzers, additional report formats, performance improvements, and documentation.

## License

MIT
