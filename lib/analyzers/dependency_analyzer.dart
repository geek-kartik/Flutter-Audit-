import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import 'base_analyzer.dart';

/// Analyzer for detecting unused pubspec dependencies.
class DependencyAnalyzer implements Analyzer {
  /// Packages that are built-in or implicitly used without explicit import.
  static const Set<String> _ignoredPackages = {
    'flutter',
    'flutter_test',
    'flutter_driver',
    'integration_test',
  };

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];
    final declaredDependencies = project.pubspec.dependencies.keys;

    // Collect all package names imported across all Dart files
    final usedPackages = <String>{};
    for (final file in project.dartFiles) {
      usedPackages.addAll(file.importedPackages);
    }

    for (final dep in declaredDependencies) {
      if (_ignoredPackages.contains(dep)) continue;

      if (!usedPackages.contains(dep)) {
        issues.add(Issue(
          id: 'unused_dependency',
          title: 'Unused Dependency: $dep',
          description:
              'Package "$dep" is declared in pubspec.yaml but never imported in any Dart source file.',
          severity: Severity.warning,
          category: 'Dependencies',
          filePath: 'pubspec.yaml',
          recommendation:
              'Remove "$dep" from pubspec.yaml if it is no longer needed.',
          scorePenalty: 2,
        ));
      }
    }

    return issues;
  }
}
