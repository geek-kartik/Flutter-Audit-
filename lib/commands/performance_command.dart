import '../analyzers/base_analyzer.dart';
import '../analyzers/performance_analyzer.dart';
import 'base_command.dart';

/// Command to audit performance bottlenecks, huge assets, and widget nesting depth.
class PerformanceCommand extends BaseAuditCommand {
  @override
  final String name = 'performance';

  @override
  final String description =
      'Audits performance bottlenecks, huge image/JSON assets, font weights, and deeply nested widget trees.';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      PerformanceAnalyzer(),
    ];
  }

  @override
  List<String> getActiveCategories() => ['Performance'];
}
