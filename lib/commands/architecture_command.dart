import 'dart:io';
import 'package:path/path.dart' as p;
import '../analyzers/architecture_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import '../models/severity.dart';
import '../reporters/csv_reporter.dart';
import '../utils/logger.dart';
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

  @override
  List<String>? getActiveCategories() => ['Architecture'];

  @override
  Future<int> run() async {
    final targetPath = p.canonicalize(argResults?['path'] as String? ?? '.');
    final pubspecFile = File(p.join(targetPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      Logger.error('No pubspec.yaml found at "$targetPath". Is this a Flutter project?');
      return 1;
    }
    Logger.info('Scanning Flutter project at "$targetPath"...');

    final report = await buildReport(targetPath);

    final warnings = report.issuesForSeverity(Severity.warning).length;
    final errors = report.issuesForSeverity(Severity.error).length;
    final infos = report.issuesForSeverity(Severity.info).length;
    Logger.info('Architecture audit: $warnings warnings, $errors errors, $infos info. Health score: ${report.healthScore}/100');

    final csvFile = File(p.join(targetPath, 'architecture_audit.csv'));
    final sink = csvFile.openWrite();
    const CsvReporter().report(report, sink: sink);
    await sink.flush();
    await sink.close();
    Logger.success('Architecture report saved to architecture_audit.csv');

    return 0;
  }
}
