import '../analyzers/asset_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import '../analyzers/dependency_analyzer.dart';
import '../analyzers/directory_analyzer.dart';
import '../analyzers/flutter_upgrade_analyzer.dart';
import '../analyzers/license_analyzer.dart';
import '../analyzers/performance_analyzer.dart';
import '../analyzers/pubspec_analyzer.dart';
import 'base_command.dart';

/// Command to run a comprehensive project audit across all analyzers.
class AuditCommand extends BaseAuditCommand {
  @override
  final String name = 'audit';

  @override
  final String description =
      'Scans Flutter project and runs all audit analyzers (dependencies, assets, performance, directory, pubspec, licenses, flutter upgrade).';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      DependencyAnalyzer(),
      AssetAnalyzer(),
      PerformanceAnalyzer(),
      DirectoryAnalyzer(),
      PubspecAnalyzer(),
      LicenseAnalyzer(),
      FlutterUpgradeAnalyzer(),
    ];
  }
}
