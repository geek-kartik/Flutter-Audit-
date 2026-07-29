import 'package:path/path.dart' as p;

/// Extension helpers for human-readable byte sizes and path utilities.
extension FileSizeExtension on int {
  /// Formats byte count as human readable string (e.g. "1.5 MB", "450 KB").
  String toHumanReadableSize() {
    if (this <= 0) return '0 B';
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

extension PathExtension on String {
  /// Normalizes path separators to standard forward slashes.
  String normalizePath() {
    return p.normalize(this).replaceAll('\\', '/');
  }

  /// Converts an absolute path to a relative path against [root].
  String toRelativePath(String root) {
    final canonSelf = p.canonicalize(this).replaceAll('\\', '/');
    final canonRoot = p.canonicalize(root).replaceAll('\\', '/');
    try {
      final rel = p.relative(canonSelf, from: canonRoot);
      return rel.replaceAll('\\', '/');
    } catch (_) {
      if (canonSelf.startsWith(canonRoot)) {
        var r = canonSelf.substring(canonRoot.length);
        if (r.startsWith('/')) r = r.substring(1);
        return r;
      }
      return canonSelf;
    }
  }


}
