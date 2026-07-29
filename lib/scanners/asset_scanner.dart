import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../models/asset_info.dart';
import '../models/pubspec_info.dart';
import '../utils/extensions.dart';

/// Scanner for finding, measuring, and hashing asset files in the project.
class AssetScanner {
  /// Scans physical asset files matching pubspec declarations or standard asset folders.
  Future<List<AssetInfo>> scan(
    String projectPath,
    PubspecInfo pubspecInfo,
  ) async {
    final assetFiles = <String, File>{};

    // 1. Gather files explicitly or implicitly declared in pubspec.yaml
    for (final declared in pubspecInfo.flutterAssets) {
      final absolute = p.join(projectPath, declared);
      final file = File(absolute);
      final dir = Directory(absolute);

      if (file.existsSync()) {
        assetFiles[file.path.normalizePath()] = file;
      } else if (dir.existsSync()) {
        // Folder declared in assets (e.g. 'assets/images/')
        try {
          final entities = dir.listSync(recursive: true);
          for (final entity in entities) {
            if (entity is File && !_shouldIgnoreFile(entity.path)) {
              assetFiles[entity.path.normalizePath()] = entity;
            }
          }
        } catch (_) {}
      }
    }

    // 2. Also check default assets/ directory if exists
    final defaultAssetsDir = Directory(p.join(projectPath, 'assets'));
    if (defaultAssetsDir.existsSync()) {
      try {
        final entities = defaultAssetsDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && !_shouldIgnoreFile(entity.path)) {
            assetFiles[entity.path.normalizePath()] = entity;
          }
        }
      } catch (_) {}
    }

    // 3. Process each asset file to generate AssetInfo
    final results = <AssetInfo>[];
    for (final entry in assetFiles.entries) {
      final file = entry.value;
      try {
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        final relPath = file.path.toRelativePath(projectPath);
        final ext = p.extension(file.path).toLowerCase();

        results.add(AssetInfo(
          relativePath: relPath,
          absolutePath: file.path.normalizePath(),
          sizeInBytes: bytes.length,
          extension: ext,
          sha256Hash: hash,
        ));
      } catch (_) {
        // Skip inaccessible files
      }
    }

    return results;
  }

  bool _shouldIgnoreFile(String path) {
    final base = p.basename(path);
    return base.startsWith('.') || base.endsWith('.DS_Store');
  }
}
