import '../analyzers/architecture_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import 'base_command.dart';

/// Command to audit code architecture, file/class sizes, and unused Dart files.
class ArchitectureCommand extends BaseAuditCommand {
  @override
  final String name = 'architecture';

  @override
  final String description =
      'Audits code architecture, component metrics, large files/widgets, duplicate imports, and unused Dart files.';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      ArchitectureAnalyzer(),
    ];
  }
}
