import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import 'base_analyzer.dart';

/// Analyzer for project directory hygiene, empty folders, duplicate file names, temp, and backup files.
class DirectoryAnalyzer implements Analyzer {
  const DirectoryAnalyzer();

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];
    final scan = project.directoryScan;

    // 1. Empty folders
    for (final emptyDir in scan.emptyDirectories) {
      issues.add(Issue(
        id: 'empty_directory',
        title: 'Empty Directory: $emptyDir',
        description: 'Directory "$emptyDir" is empty.',
        severity: Severity.info,
        category: 'Directory',
        filePath: emptyDir,
        recommendation:
            'Remove empty directory or add required assets/files.',
        scorePenalty: 1,
      ));
    }

    // 3. Temporary files
    for (final tempFile in scan.temporaryFiles) {
      issues.add(Issue(
        id: 'temp_file',
        title: 'Temporary File Found: $tempFile',
        description: 'Temporary system or IDE file "$tempFile" present in repository.',
        severity: Severity.warning,
        category: 'Directory',
        filePath: tempFile,
        recommendation: 'Remove temporary file and ensure it is added to .gitignore.',
        scorePenalty: 1,
      ));
    }

    // 4. Backup files
    for (final backupFile in scan.backupFiles) {
      issues.add(Issue(
        id: 'backup_file',
        title: 'Backup File Found: $backupFile',
        description: 'Leftover backup file "$backupFile" found in project directory.',
        severity: Severity.warning,
        category: 'Directory',
        filePath: backupFile,
        recommendation: 'Delete leftover backup files before committing code.',
        scorePenalty: 1,
      ));
    }

    return issues;
  }
}
