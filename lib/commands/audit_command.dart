import '../analyzers/architecture_analyzer.dart';
import '../analyzers/asset_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import '../analyzers/dependency_analyzer.dart';
import '../analyzers/directory_analyzer.dart';
import '../analyzers/performance_analyzer.dart';
import '../analyzers/pubspec_analyzer.dart';
import 'base_command.dart';

/// Command to run a comprehensive project audit across all analyzers.
class AuditCommand extends BaseAuditCommand {
  @override
  final String name = 'audit';

  @override
  final String description =
      'Scans Flutter project and runs all audit analyzers (dependencies, assets, architecture, performance, directory, pubspec).';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      DependencyAnalyzer(),
      AssetAnalyzer(),
      ArchitectureAnalyzer(),
      PerformanceAnalyzer(),
      DirectoryAnalyzer(),
      PubspecAnalyzer(),
    ];
  }
}
