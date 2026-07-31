import 'dart:io';
import 'package:path/path.dart' as p;
import '../analyzers/architecture_analyzer.dart';
import '../analyzers/asset_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import '../analyzers/dependency_analyzer.dart';
import '../analyzers/directory_analyzer.dart';
import '../analyzers/flutter_upgrade_analyzer.dart';
import '../analyzers/license_analyzer.dart';
import '../analyzers/performance_analyzer.dart';
import '../analyzers/pubspec_analyzer.dart';
import '../models/issue.dart';
import '../models/report.dart';
import '../models/severity.dart';
import '../reporters/console_reporter.dart';
import '../reporters/csv_reporter.dart';
import '../reporters/json_reporter.dart';
import '../reporters/markdown_reporter.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// Command to run a comprehensive project audit across all analyzers.
class AuditCommand extends BaseAuditCommand {
  @override
  final String name = 'audit';

  @override
  final String description =
      'Scans Flutter project and runs all audit analyzers (dependencies, assets, architecture, performance, directory, pubspec, licenses, flutter upgrade).';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      DependencyAnalyzer(),
      AssetAnalyzer(),
      ArchitectureAnalyzer(),
      PerformanceAnalyzer(),
      DirectoryAnalyzer(),
      PubspecAnalyzer(),
      LicenseAnalyzer(),
      FlutterUpgradeAnalyzer(),
    ];
  }

  @override
  Future<int> run() async {
    final targetPath = p.canonicalize(argResults?['path'] as String? ?? '.');
    final isJson = argResults?['json'] as bool? ?? false;
    final isMarkdown = argResults?['markdown'] as bool? ?? false;
    final isCsv = argResults?['csv'] as bool? ?? false;
    final outputPath = argResults?['output'] as String?;

    final pubspecFile = File(p.join(targetPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      Logger.error('No pubspec.yaml found at "$targetPath". Is this a Flutter project?');
      return 1;
    }

    if (!isJson && outputPath == null) {
      Logger.info('Scanning Flutter project at "$targetPath"...');
    }

    var report = await buildReport(targetPath);

    report = await _extractToCsv(report, 'Architecture', targetPath, 'architecture_audit.csv');
    report = await _extractToCsv(report, 'Performance', targetPath, 'performance_audit.csv');
    report = await _extractToCsv(report, 'Directory', targetPath, 'directory_audit.csv');

    // Render Output
    IOSink? fileSink;
    if (outputPath != null) {
      final outputFile = File(outputPath);
      fileSink = outputFile.openWrite();
    }

    if (isJson) {
      const JsonReporter().report(report, sink: fileSink);
    } else if (isCsv) {
      const CsvReporter().report(report, sink: fileSink);
    } else if (isMarkdown) {
      const MarkdownReporter().report(report, sink: fileSink);
    } else {
      const ConsoleReporter().report(report, sink: fileSink);
    }

    if (fileSink != null) {
      await fileSink.flush();
      await fileSink.close();
      Logger.success('Report successfully written to $outputPath');
    }

    if (!isJson && !isCsv && !isMarkdown && outputPath == null) {
      await _writeConsoleReportToMarkdown(targetPath, report);
    }

    return 0;
  }

  /// Writes the console report output into `audit_report.md` with a current timestamp.
  Future<void> _writeConsoleReportToMarkdown(String targetPath, Report report) async {
    final reportFile = File(p.join(targetPath, 'audit_report.md'));
    final sink = reportFile.openWrite();
    Logger.enableColors = false;
    try {
      sink.writeln('# Flutter Audit Report');
      sink.writeln();
      sink.writeln('```');
      sink.writeln('Generated at: ${DateTime.now().toIso8601String()}');
      sink.writeln();
      const ConsoleReporter().report(report, sink: sink);
      sink.writeln('```');
    } finally {
      Logger.enableColors = true;
    }
    await sink.flush();
    await sink.close();
    Logger.success('Audit report saved to ${reportFile.path}');
  }

  Future<Report> _extractToCsv(Report report, String category, String targetPath, String csvFilename) async {
    final issues = report.issuesForCategory(category);
    if (issues.isEmpty) return report;

    final filteredReport = Report(
      projectName: report.projectName,
      projectPath: report.projectPath,
      timestamp: report.timestamp,
      issues: issues,
      metrics: report.metrics,
      activeCategories: [category],
    );
    final csvFile = File(p.join(targetPath, csvFilename));
    final sink = csvFile.openWrite();
    const CsvReporter().report(filteredReport, sink: sink);
    await sink.flush();
    await sink.close();

    final warnings = issues.where((i) => i.severity == Severity.warning).length;
    final errors = issues.where((i) => i.severity == Severity.error).length;
    final infos = issues.where((i) => i.severity == Severity.info).length;
    final otherIssues = report.issues
        .where((i) => i.category != category)
        .toList();
    otherIssues.add(Issue(
      id: '${category.toLowerCase()}_summary',
      title: '$warnings warnings, $errors errors, $infos info — see $csvFilename',
      description: '${category} audit results written to $csvFilename.',
      severity: Severity.info,
      category: category,
      filePath: csvFilename,
      recommendation: 'Open $csvFilename for full details.',
      scorePenalty: 0,
    ));
    return Report(
      projectName: report.projectName,
      projectPath: report.projectPath,
      timestamp: report.timestamp,
      issues: otherIssues,
      metrics: report.metrics,
      activeCategories: report.activeCategories,
    );
  }
}
