import 'dart:io';
import '../models/report.dart';
import 'reporter.dart';

/// Reporter that formats audit results as GitHub-flavored Markdown.
class MarkdownReporter implements Reporter {
  const MarkdownReporter();

  @override
  void report(Report report, {IOSink? sink}) {
    final content = generateMarkdown(report);
    if (sink != null) {
      sink.write(content);
    } else {
      // ignore: avoid_print
      print(content);
    }
  }

  /// Generates markdown text for [report].
  String generateMarkdown(Report report) {
    final buffer = StringBuffer();

    buffer.writeln('# Flutter Project Audit Report');
    buffer.writeln();
    buffer.writeln('**Project Name:** `${report.projectName}`  ');
    buffer.writeln('**Project Path:** `${report.projectPath}`  ');
    buffer.writeln('**Audit Timestamp:** `${report.timestamp.toIso8601String()}`  ');
    buffer.writeln();

    buffer.writeln('## 📊 Project Health Score: ${report.healthScore} / 100');
    buffer.writeln();

    buffer.writeln('### Metrics Summary');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('| --- | --- |');
    buffer.writeln('| Total Issues | `${report.issues.length}` |');
    buffer.writeln('| Total Packages | `${report.metrics["packageCount"] ?? 0}` |');
    buffer.writeln('| Total Assets | `${report.metrics["assetCount"] ?? 0}` |');
    buffer.writeln('| Total Dart Files | `${report.metrics["dartFileCount"] ?? 0}` |');
    buffer.writeln('| Total Lines of Code | `${report.metrics["totalLoc"] ?? 0}` |');
    buffer.writeln();

    final categories = report.activeCategories ?? [
      'Dependencies',
      'Assets',
      'Performance',
      'Directory',
      'Pubspec',
      'Licenses',
      'Flutter',
    ];

    for (final cat in categories) {
      final issues = report.issuesForCategory(cat);
      buffer.writeln('## $cat');
      buffer.writeln();

      if (issues.isEmpty) {
        buffer.writeln('✅ *No issues detected in $cat.*');
        buffer.writeln();
      } else {
        buffer.writeln('| Severity | Issue Title | Location | Recommendation |');
        buffer.writeln('| --- | --- | --- | --- |');
        for (final issue in issues) {
          final badge = issue.severity.name == 'error'
              ? '🔴 ERROR'
              : issue.severity.name == 'warning'
                  ? '🟡 WARNING'
                  : '🔵 INFO';
          final loc = issue.filePath != null
              ? '`${issue.filePath}${issue.line != null ? ":${issue.line}" : ""}`'
              : '-';
          final rec = issue.recommendation ?? '-';

          buffer.writeln('| $badge | ${issue.title} | $loc | $rec |');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
