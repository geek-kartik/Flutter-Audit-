import '../analyzers/base_analyzer.dart';
import '../analyzers/dependency_analyzer.dart';
import '../analyzers/pubspec_analyzer.dart';
import 'base_command.dart';

/// Command to scan and audit package dependencies.
class DependenciesCommand extends BaseAuditCommand {
  @override
  final String name = 'dependencies';

  @override
  final String description =
      'Scans dependencies in pubspec.yaml against source imports to detect unused dependencies and pubspec issues.';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      DependencyAnalyzer(),
      PubspecAnalyzer(),
    ];
  }

  @override
  List<String> getActiveCategories() => ['Dependencies', 'Pubspec'];
}
