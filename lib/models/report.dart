import 'dart:math';
import 'package:meta/meta.dart';
import 'issue.dart';
import 'severity.dart';

/// Aggregated report of a project audit containing issues, score, and metrics.
@immutable
class Report {
  final String projectName;
  final String projectPath;
  final DateTime timestamp;
  final List<Issue> issues;
  final Map<String, dynamic> metrics;

  const Report({
    required this.projectName,
    required this.projectPath,
    required this.timestamp,
    required this.issues,
    required this.metrics,
  });

  /// Calculates the project health score from 0 to 100 based on issue score penalties.
  int get healthScore {
    final totalPenalty =
        issues.fold<int>(0, (sum, issue) => sum + issue.scorePenalty);
    return max(0, 100 - totalPenalty);
  }

  /// Filter issues by category.
  List<Issue> issuesForCategory(String category) {
    return issues.where((issue) => issue.category == category).toList();
  }

  /// Filter issues by severity.
  List<Issue> issuesForSeverity(Severity severity) {
    return issues.where((issue) => issue.severity == severity).toList();
  }

  /// Converts report into a structured JSON map.
  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'projectPath': projectPath,
      'timestamp': timestamp.toIso8601String(),
      'healthScore': healthScore,
      'metrics': metrics,
      'summary': {
        'totalIssues': issues.length,
        'infoCount': issuesForSeverity(Severity.info).length,
        'warningCount': issuesForSeverity(Severity.warning).length,
        'errorCount': issuesForSeverity(Severity.error).length,
      },
      'issues': issues.map((i) => i.toJson()).toList(),
    };
  }
}
