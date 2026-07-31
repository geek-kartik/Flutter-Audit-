import 'dart:io';
import 'package:path/path.dart' as p;
import '../analyzers/base_analyzer.dart';
import '../analyzers/performance_analyzer.dart';
import '../models/severity.dart';
import '../reporters/csv_reporter.dart';
import '../utils/logger.dart';
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
    Logger.info('Performance audit: $warnings warnings, $errors errors, $infos info. Health score: ${report.healthScore}/100');

    if (report.issues.isNotEmpty) {
      final csvFile = File(p.join(targetPath, 'performance_audit.csv'));
      final sink = csvFile.openWrite();
      const CsvReporter().report(report, sink: sink);
      await sink.flush();
      await sink.close();
      Logger.success('Performance report saved to performance_audit.csv');
    }

    return 0;
  }
}
