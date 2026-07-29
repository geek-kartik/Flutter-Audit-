import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import '../utils/config.dart';
import '../utils/extensions.dart';
import 'base_analyzer.dart';

/// Analyzer for detecting performance bottlenecks, asset sizes, and widget nesting depth.
class PerformanceAnalyzer implements Analyzer {
  final AuditConfig config;

  const PerformanceAnalyzer({this.config = const AuditConfig()});

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];

    // 1. HUGE ASSETS PERFORMANCE WARNINGS
    for (final asset in project.assets) {
      final size = asset.sizeInBytes;
      final relPath = asset.relativePath;
      final ext = asset.extension;

      if (_isImage(ext) && size > config.hugeImageThresholdBytes) {
        issues.add(Issue(
          id: 'huge_image_performance',
          title: 'Huge Image Asset: $relPath (${size.toHumanReadableSize()})',
          description:
              'Image asset "$relPath" is ${size.toHumanReadableSize()}. Decoding huge image buffers consumes substantial RAM and GPU memory.',
          severity: Severity.error,
          category: 'Performance',
          filePath: relPath,
          recommendation:
              'Downscale image dimensions and use image compression or network image caching.',
          scorePenalty: 2,
        ));
      } else if (ext == '.json' && size > 500 * 1024) {
        issues.add(Issue(
          id: 'huge_json_performance',
          title: 'Huge JSON File: $relPath (${size.toHumanReadableSize()})',
          description:
              'JSON asset "$relPath" is ${size.toHumanReadableSize()}. Parsing large JSON payloads on the main isolate blocks UI frames.',
          severity: Severity.warning,
          category: 'Performance',
          filePath: relPath,
          recommendation:
              'Parse JSON asynchronously in a background isolate (`compute` / `Isolate.run`).',
          scorePenalty: 2,
        ));
      }
    }

    // 2. LARGE FONT FAMILIES PERFORMANCE
    for (final font in project.pubspec.flutterFonts) {
      int totalSizeBytes = 0;
      for (final fontAssetPath in font.assetPaths) {
        for (final asset in project.assets) {
          if (asset.relativePath == fontAssetPath ||
              asset.relativePath.endsWith(fontAssetPath)) {
            totalSizeBytes += asset.sizeInBytes;
          }
        }
      }

      if (totalSizeBytes > 3 * 1024 * 1024) {
        issues.add(Issue(
          id: 'large_font_family',
          title: 'Heavy Font Family: "${font.family}" (${totalSizeBytes.toHumanReadableSize()})',
          description:
              'Font family "${font.family}" consumes ${totalSizeBytes.toHumanReadableSize()} across ${font.assetPaths.length} font weights/styles.',
          severity: Severity.warning,
          category: 'Performance',
          filePath: 'pubspec.yaml',
          recommendation:
              'Limit font variants to essential weights (e.g. Regular 400 and Bold 700).',
          scorePenalty: 2,
        ));
      }
    }

    // 3. LARGE GENERATED FILES AND DEEPLY NESTED WIDGET TREES
    for (final file in project.dartFiles) {
      final isGenerated = file.relativePath.endsWith('.g.dart') ||
          file.relativePath.endsWith('.freezed.dart');

      if (isGenerated && file.lineCount > 1000) {
        issues.add(Issue(
          id: 'large_generated_file',
          title: 'Huge Generated File: ${file.relativePath} (${file.lineCount} lines)',
          description:
              'Generated file "${file.relativePath}" has ${file.lineCount} lines, which slows down Dart analyzer indexing and build performance.',
          severity: Severity.info,
          category: 'Performance',
          filePath: file.relativePath,
          recommendation:
              'Split models or limit generation scope for code generators.',
          scorePenalty: 1,
        ));
      }

      if (!isGenerated && file.lineCount > 500) {
        issues.add(Issue(
          id: 'large_dart_file_performance',
          title: 'Large Source File: ${file.relativePath} (${file.lineCount} lines)',
          description:
              'Dart file contains ${file.lineCount} lines, increasing compilation time.',
          severity: Severity.info,
          category: 'Performance',
          filePath: file.relativePath,
          recommendation: 'Decompose source file into modular sub-files.',
          scorePenalty: 1,
        ));
      }

      for (final cls in file.classes) {
        if (cls.maxWidgetNestingDepth > 8) {
          issues.add(Issue(
            id: 'deep_widget_tree_performance',
            title: 'Excessively Nested Widget Tree in ${cls.name} (depth: ${cls.maxWidgetNestingDepth})',
            description:
                'Widget "${cls.name}" has a tree depth of ${cls.maxWidgetNestingDepth} levels. Deep widget trees increase build and layout traversal cost.',
            severity: Severity.warning,
            category: 'Performance',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
                'Break down build method into const sub-widgets to optimize rebuild performance.',
            scorePenalty: 2,
          ));
        }
      }
    }

    return issues;
  }

  bool _isImage(String ext) =>
      ext == '.png' ||
      ext == '.jpg' ||
      ext == '.jpeg' ||
      ext == '.gif' ||
      ext == '.webp' ||
      ext == '.bmp';
}
