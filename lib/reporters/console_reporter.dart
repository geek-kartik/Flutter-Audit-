import 'dart:io';
import '../models/report.dart';
import '../utils/logger.dart';
import 'reporter.dart';

/// Console reporter that renders colored, human-readable terminal output.
class ConsoleReporter implements Reporter {
  const ConsoleReporter();

  @override
  void report(Report report, {IOSink? sink}) {
    Logger.header('Flutter Audit Report: ${report.projectName}', sink: sink);

    final categories = [
      'Dependencies',
      'Assets',
      'Architecture',
      'Performance',
      'Directory',
      'Pubspec',
    ];

    for (final category in categories) {
      final categoryIssues = report.issuesForCategory(category);

      _printSectionHeader(category, sink: sink);

      // Print metric summary if available
      _printCategoryMetrics(category, report, categoryIssues.length, sink: sink);

      if (categoryIssues.isEmpty) {
        Logger.success('No issues detected in $category', sink: sink);
      } else {
        for (final issue in categoryIssues) {
          final prefix = issue.severity.name == 'error'
              ? Logger.colorize('✗', '31')
              : issue.severity.name == 'warning'
                  ? Logger.colorize('⚠', '33')
                  : Logger.colorize('ℹ', '36');

          final locationStr = issue.filePath != null
              ? ' (${issue.filePath}${issue.line != null ? ":${issue.line}" : ""})'
              : '';

          _writeln('  $prefix ${issue.title}$locationStr', sink: sink);
          if (issue.recommendation != null) {
            _writeln(
                '    ${Logger.colorize("➜ Recommendation:", "90")} ${issue.recommendation}',
                sink: sink);
          }
        }
      }
    }

    _printHealthScore(report.healthScore, sink: sink);
  }

  void _printSectionHeader(String title, {IOSink? sink}) {
    _writeln('', sink: sink);
    _writeln(Logger.bold(title), sink: sink);
    _writeln(Logger.colorize('────────────────────────────', '90'), sink: sink);
  }

  void _printCategoryMetrics(
      String category, Report report, int issueCount, {IOSink? sink}) {
    final metrics = report.metrics;
    if (category == 'Dependencies' && metrics.containsKey('packageCount')) {
      _writeln('  ✓ ${metrics["packageCount"]} packages declared', sink: sink);
    } else if (category == 'Assets' && metrics.containsKey('assetCount')) {
      _writeln('  ✓ ${metrics["assetCount"]} asset files scanned', sink: sink);
    } else if (category == 'Architecture' && metrics.containsKey('dartFileCount')) {
      _writeln(
          '  ✓ ${metrics["dartFileCount"]} Dart files analysed (${metrics["totalLoc"] ?? 0} LOC)',
          sink: sink);
    }
  }

  void _printHealthScore(int score, {IOSink? sink}) {
    _writeln('', sink: sink);
    _writeln(Logger.bold('Health Score'), sink: sink);
    _writeln(Logger.colorize('────────────────────────────', '90'), sink: sink);

    String scoreColor;
    if (score >= 90) {
      scoreColor = '32'; // Green
    } else if (score >= 70) {
      scoreColor = '33'; // Yellow
    } else {
      scoreColor = '31'; // Red
    }

    final formattedScore =
        Logger.colorize(Logger.bold('$score / 100'), scoreColor);
    _writeln('  Project Health: $formattedScore', sink: sink);
    _writeln('', sink: sink);
  }

  void _writeln(String text, {IOSink? sink}) {
    if (sink != null) {
      sink.writeln(text);
    } else {
      // ignore: avoid_print
      print(text);
    }
  }
}
