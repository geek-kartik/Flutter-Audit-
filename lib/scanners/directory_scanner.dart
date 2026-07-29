import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import '../models/directory_info.dart';
import '../utils/extensions.dart';

/// Scanner for directory structure, file naming duplicates, temp and backup files.
class DirectoryScanner {
  static const List<String> targetDirs = [
    'lib',
    'test',
    'assets',
    'android',
    'ios',
    'web',
    'windows',
    'linux',
    'macos',
  ];

  static final List<Glob> generatedGlobs = [
    Glob('*.g.dart'),
    Glob('*.freezed.dart'),
    Glob('*.mocks.dart'),
    Glob('*.gr.dart'),
    Glob('*.config.dart'),
  ];

  static final List<Glob> tempGlobs = [
    Glob('.DS_Store', caseSensitive: false),
    Glob('thumbs.db', caseSensitive: false),
    Glob('*.tmp'),
    Glob('*.swp'),
    Glob('*.swo'),
  ];

  static final List<Glob> backupGlobs = [
    Glob('*.bak'),
    Glob('*.old'),
    Glob('*~'),
    Glob('*.orig'),
  ];

  /// Scans the target project directory structure.
  Future<DirectoryScanResult> scan(String projectPath) async {
    final emptyDirectories = <String>[];
    final filenameToPaths = <String, List<String>>{};
    final generatedFiles = <String>[];
    final temporaryFiles = <String>[];
    final backupFiles = <String>[];

    for (final dirName in targetDirs) {
      final dirPath = p.join(projectPath, dirName);
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      _scanDirectory(
        dir,
        projectPath,
        emptyDirectories,
        filenameToPaths,
        generatedFiles,
        temporaryFiles,
        backupFiles,
      );
    }

    // Filter duplicate filenames to only those occurring > 1 time
    final duplicateFilenames = <String, List<String>>{};
    filenameToPaths.forEach((filename, paths) {
      if (paths.length > 1) {
        duplicateFilenames[filename] = paths;
      }
    });

    return DirectoryScanResult(
      emptyDirectories: emptyDirectories,
      duplicateFilenames: duplicateFilenames,
      generatedFiles: generatedFiles,
      temporaryFiles: temporaryFiles,
      backupFiles: backupFiles,
    );
  }

  void _scanDirectory(
    Directory dir,
    String projectPath,
    List<String> emptyDirectories,
    Map<String, List<String>> filenameToPaths,
    List<String> generatedFiles,
    List<String> temporaryFiles,
    List<String> backupFiles,
  ) {
    try {
      final entities = dir.listSync(recursive: false);

      if (entities.isEmpty) {
        emptyDirectories.add(dir.path.toRelativePath(projectPath));
        return;
      }

      for (final entity in entities) {
        if (entity is Directory) {
          if (p.basename(entity.path).startsWith('.')) continue;

          _scanDirectory(
            entity,
            projectPath,
            emptyDirectories,
            filenameToPaths,
            generatedFiles,
            temporaryFiles,
            backupFiles,
          );
        } else if (entity is File) {
          final filename = p.basename(entity.path);
          final relPath = entity.path.toRelativePath(projectPath);

          if (!filename.startsWith('.') && !_isGenerated(filename)) {
            filenameToPaths.putIfAbsent(filename, () => []).add(relPath);
          }

          if (_isGenerated(filename)) {
            generatedFiles.add(relPath);
          }

          if (_isTemp(filename)) {
            temporaryFiles.add(relPath);
          }

          if (_isBackup(filename)) {
            backupFiles.add(relPath);
          }
        }
      }
    } catch (_) {}
  }

  bool _isGenerated(String filename) {
    return generatedGlobs.any((glob) => glob.matches(filename));
  }

  bool _isTemp(String filename) {
    return tempGlobs.any((glob) => glob.matches(filename));
  }

  bool _isBackup(String filename) {
    return backupGlobs.any((glob) => glob.matches(filename));
  }
}

