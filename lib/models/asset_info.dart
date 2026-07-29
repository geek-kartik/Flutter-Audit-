import 'package:meta/meta.dart';

/// Information about a single asset file in the project.
@immutable
class AssetInfo {
  /// Relative path of the asset (e.g. 'assets/images/logo.png').
  final String relativePath;

  /// Absolute file system path.
  final String absolutePath;

  /// Size of the asset file in bytes.
  final int sizeInBytes;

  /// File extension (lowercase, e.g. '.png', '.svg', '.json', '.ttf').
  final String extension;

  /// SHA256 digest of the asset content.
  final String sha256Hash;

  const AssetInfo({
    required this.relativePath,
    required this.absolutePath,
    required this.sizeInBytes,
    required this.extension,
    required this.sha256Hash,
  });
}
