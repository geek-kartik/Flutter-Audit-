import 'package:meta/meta.dart';
import 'asset_info.dart';
import 'dart_file_info.dart';
import 'directory_info.dart';
import 'pubspec_info.dart';

/// Aggregates all scanned information for a target Flutter project.
@immutable
class Project {
  /// Absolute path to the project root directory.
  final String rootPath;

  /// Pubspec metadata and dependencies.
  final PubspecInfo pubspec;

  /// List of scanned Dart files and their AST metadata.
  final List<DartFileInfo> dartFiles;

  /// List of physical asset files found in the project.
  final List<AssetInfo> assets;

  /// Results of directory scanning (empty folders, temp files, etc.).
  final DirectoryScanResult directoryScan;

  const Project({
    required this.rootPath,
    required this.pubspec,
    required this.dartFiles,
    required this.assets,
    required this.directoryScan,
  });

  /// Finds a [DartFileInfo] by relative or absolute path.
  DartFileInfo? findDartFile(String path) {
    for (final file in dartFiles) {
      if (file.relativePath == path || file.absolutePath == path) {
        return file;
      }
    }
    return null;
  }
}
