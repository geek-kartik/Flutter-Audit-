import 'package:path/path.dart' as p;
import '../models/asset_info.dart';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import '../utils/config.dart';
import '../utils/extensions.dart';
import 'base_analyzer.dart';

/// Analyzer for detecting unused assets, duplicate asset files, and large asset sizes.
class AssetAnalyzer implements Analyzer {
  final AuditConfig config;

  const AssetAnalyzer({this.config = const AuditConfig()});

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];

    // Collect all asset references from Dart files AST
    final allStringLiterals = <String>{};
    final explicitAssetUsages = <String>{};

    for (final dartFile in project.dartFiles) {
      allStringLiterals.addAll(dartFile.stringLiterals);
      for (final usage in dartFile.assetUsages) {
        explicitAssetUsages.add(usage.assetPathOrName);
      }
    }

    // 1. UNUSED ASSETS & LARGE ASSETS
    final hashToAssets = <String, List<AssetInfo>>{};

    for (final asset in project.assets) {
      // Group by hash for duplicate check
      hashToAssets.putIfAbsent(asset.sha256Hash, () => []).add(asset);

      // Check if referenced
      final relPath = asset.relativePath;
      final basename = p.basename(relPath);

      final isReferenced = explicitAssetUsages.contains(relPath) ||
          explicitAssetUsages.contains(basename) ||
          allStringLiterals.any((str) =>
              str.contains(relPath) ||
              str.contains(basename) ||
              relPath.contains(str));

      if (!isReferenced) {
        issues.add(Issue(
          id: 'unused_asset',
          title: 'Unused Asset: $relPath',
          description:
              'Asset file "$relPath" is present in the project but never referenced in Dart code.',
          severity: Severity.warning,
          category: 'Assets',
          filePath: relPath,
          recommendation:
              'Remove "$relPath" from project assets if unused to reduce app bundle size.',
          scorePenalty: 1,
        ));
      }

      // Check Large Asset sizes
      final size = asset.sizeInBytes;
      final ext = asset.extension;

      if (_isImage(ext) && size > config.largeImageThresholdBytes) {
        issues.add(Issue(
          id: 'large_image',
          title: 'Large Image Asset: $relPath (${size.toHumanReadableSize()})',
          description:
              'Image asset "$relPath" is ${size.toHumanReadableSize()}, exceeding the recommended ${config.largeImageThresholdBytes.toHumanReadableSize()} limit.',
          severity: Severity.warning,
          category: 'Assets',
          filePath: relPath,
          recommendation:
              'Compress image using WebP/PNG quantizer or resize dimensions before bundling.',
          scorePenalty: 2,
        ));
      } else if (ext == '.svg' && size > config.largeSvgThresholdBytes) {
        issues.add(Issue(
          id: 'large_svg',
          title: 'Large SVG Asset: $relPath (${size.toHumanReadableSize()})',
          description:
              'SVG asset "$relPath" is ${size.toHumanReadableSize()}, which may impact vector rendering performance.',
          severity: Severity.warning,
          category: 'Assets',
          filePath: relPath,
          recommendation:
              'Optimize SVG paths using SVGO or remove unnecessary metadata.',
          scorePenalty: 2,
        ));
      } else if (ext == '.json' && size > config.largeJsonThresholdBytes) {
        issues.add(Issue(
          id: 'large_json',
          title: 'Large JSON/Lottie Asset: $relPath (${size.toHumanReadableSize()})',
          description:
              'JSON asset "$relPath" is ${size.toHumanReadableSize()}, which can increase startup time and RAM usage.',
          severity: Severity.warning,
          category: 'Assets',
          filePath: relPath,
          recommendation:
              'Minify JSON or simplify Lottie animation keyframes.',
          scorePenalty: 2,
        ));
      } else if (_isFont(ext) && size > config.largeFontThresholdBytes) {
        issues.add(Issue(
          id: 'large_font',
          title: 'Large Font File: $relPath (${size.toHumanReadableSize()})',
          description:
              'Font file "$relPath" is ${size.toHumanReadableSize()}, which significantly inflates application binary size.',
          severity: Severity.warning,
          category: 'Assets',
          filePath: relPath,
          recommendation:
              'Subset font to only required glyphs or use variable fonts.',
          scorePenalty: 2,
        ));
      }
    }

    // 2. DUPLICATE ASSETS
    hashToAssets.forEach((hash, assets) {
      if (assets.length > 1) {
        final paths = assets.map((a) => a.relativePath).join(', ');
        issues.add(Issue(
          id: 'duplicate_asset',
          title: 'Duplicate Asset Files Detected',
          description:
              'Identical content (SHA256: ${hash.substring(0, 8)}...) found in multiple asset files: [$paths].',
          severity: Severity.warning,
          category: 'Assets',
          filePath: assets.first.relativePath,
          recommendation:
              'Consolidate duplicate assets into a single shared file.',
          scorePenalty: 2,
        ));
      }
    });

    return issues;
  }

  bool _isImage(String ext) =>
      ext == '.png' ||
      ext == '.jpg' ||
      ext == '.jpeg' ||
      ext == '.gif' ||
      ext == '.webp' ||
      ext == '.bmp';

  bool _isFont(String ext) =>
      ext == '.ttf' || ext == '.otf' || ext == '.woff' || ext == '.woff2';
}
