/// A modular offline CLI tool that scans Flutter projects for unused dependencies,
/// unused assets, duplicate assets, large files, architecture warnings, and performance bottlenecks.
library flutter_audit;

export 'analyzers/architecture_analyzer.dart';
export 'analyzers/asset_analyzer.dart';
export 'analyzers/base_analyzer.dart';
export 'analyzers/dependency_analyzer.dart';
export 'analyzers/directory_analyzer.dart';
export 'analyzers/performance_analyzer.dart';
export 'analyzers/pubspec_analyzer.dart';

export 'commands/architecture_command.dart';
export 'commands/assets_command.dart';
export 'commands/audit_command.dart';
export 'commands/base_command.dart';
export 'commands/dependencies_command.dart';
export 'commands/performance_command.dart';

export 'models/asset_info.dart';
export 'models/dart_file_info.dart';
export 'models/directory_info.dart';
export 'models/issue.dart';
export 'models/project.dart';
export 'models/pubspec_info.dart';
export 'models/report.dart';
export 'models/severity.dart';

export 'reporters/console_reporter.dart';
export 'reporters/json_reporter.dart';
export 'reporters/markdown_reporter.dart';
export 'reporters/reporter.dart';

export 'scanners/asset_scanner.dart';
export 'scanners/dart_file_scanner.dart';
export 'scanners/directory_scanner.dart';
export 'scanners/import_scanner.dart';
export 'scanners/pubspec_scanner.dart';

export 'utils/config.dart';
export 'utils/extensions.dart';
export 'utils/logger.dart';
