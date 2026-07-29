import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import 'base_analyzer.dart';

/// Analyzer for pubspec.yaml declaration integrity, missing files, and duplicate entries.
class PubspecAnalyzer implements Analyzer {
  const PubspecAnalyzer();

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];
    final pubspec = project.pubspec;

    // 1. Duplicate asset declarations in pubspec.yaml
    final seenAssets = <String, int>{};
    for (final assetPath in pubspec.flutterAssets) {
      seenAssets[assetPath] = (seenAssets[assetPath] ?? 0) + 1;
    }
    seenAssets.forEach((assetPath, count) {
      if (count > 1) {
        issues.add(Issue(
          id: 'duplicate_pubspec_asset',
          title: 'Duplicate Asset Declaration: $assetPath',
          description:
              'Asset path "$assetPath" is declared $count times in pubspec.yaml.',
          severity: Severity.warning,
          category: 'Pubspec',
          filePath: 'pubspec.yaml',
          recommendation: 'Remove duplicate asset entries from pubspec.yaml.',
          scorePenalty: 1,
        ));
      }
    });

    // 2. Asset files/folders declared in pubspec.yaml that do not exist on disk
    for (final assetPath in pubspec.flutterAssets) {
      final absPath = p.join(project.rootPath, assetPath);
      final fileExists = File(absPath).existsSync();
      final dirExists = Directory(absPath).existsSync();

      if (!fileExists && !dirExists) {
        issues.add(Issue(
          id: 'missing_asset_file',
          title: 'Missing Asset File: $assetPath',
          description:
              'Asset path "$assetPath" is declared in pubspec.yaml but does not exist on disk.',
          severity: Severity.error,
          category: 'Pubspec',
          filePath: 'pubspec.yaml',
          recommendation:
              'Create missing file/folder or remove declaration from pubspec.yaml.',
          scorePenalty: 2,
        ));
      }
    }

    // 3. Duplicate font families and missing font files
    final seenFontFamilies = <String, int>{};
    for (final font in pubspec.flutterFonts) {
      seenFontFamilies[font.family] = (seenFontFamilies[font.family] ?? 0) + 1;

      for (final fontPath in font.assetPaths) {
        final absPath = p.join(project.rootPath, fontPath);
        if (!File(absPath).existsSync()) {
          issues.add(Issue(
            id: 'missing_font_file',
            title: 'Missing Font File: $fontPath',
            description:
                'Font asset "$fontPath" for family "${font.family}" is declared in pubspec.yaml but does not exist on disk.',
            severity: Severity.error,
            category: 'Pubspec',
            filePath: 'pubspec.yaml',
            recommendation:
              'Place font file at "$fontPath" or update pubspec.yaml font declaration.',
            scorePenalty: 2,
          ));
        }
      }
    }

    seenFontFamilies.forEach((family, count) {
      if (count > 1) {
        issues.add(Issue(
          id: 'duplicate_pubspec_font',
          title: 'Duplicate Font Family Declaration: $family',
          description:
              'Font family "$family" is declared $count times in pubspec.yaml.',
          severity: Severity.warning,
          category: 'Pubspec',
          filePath: 'pubspec.yaml',
          recommendation:
              'Consolidate font declarations under a single "$family" block in pubspec.yaml.',
          scorePenalty: 1,
        ));
      }
    });

    // 4. Unused dependency overrides
    for (final overrideKey in pubspec.dependencyOverrides.keys) {
      if (!pubspec.dependencies.containsKey(overrideKey) &&
          !pubspec.devDependencies.containsKey(overrideKey)) {
        issues.add(Issue(
          id: 'unused_dependency_override',
          title: 'Unused Dependency Override: $overrideKey',
          description:
              'Dependency override "$overrideKey" is declared in pubspec.yaml but not present in dependencies or dev_dependencies.',
          severity: Severity.warning,
          category: 'Pubspec',
          filePath: 'pubspec.yaml',
          recommendation:
              'Remove unused dependency_overrides entry from pubspec.yaml.',
          scorePenalty: 1,
        ));
      }
    }

    return issues;
  }
}
