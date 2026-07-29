import 'package:meta/meta.dart';

/// Results from scanning project directories.
@immutable
class DirectoryScanResult {
  /// Paths of directories that are empty.
  final List<String> emptyDirectories;

  /// Map of file basename to list of paths where files with identical names exist.
  final Map<String, List<String>> duplicateFilenames;

  /// Code generator files (e.g. '.g.dart', '.freezed.dart').
  final List<String> generatedFiles;

  /// Temporary files (e.g. '.DS_Store', '.tmp').
  final List<String> temporaryFiles;

  /// Backup files (e.g. '.bak', '.old', '~').
  final List<String> backupFiles;

  const DirectoryScanResult({
    required this.emptyDirectories,
    required this.duplicateFilenames,
    required this.generatedFiles,
    required this.temporaryFiles,
    required this.backupFiles,
  });
}
