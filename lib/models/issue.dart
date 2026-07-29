import 'package:meta/meta.dart';
import 'severity.dart';

/// Represents a single issue detected during project auditing.
@immutable
class Issue {
  /// Unique identifier of the issue type (e.g. 'unused_dependency').
  final String id;

  /// Human-readable title of the issue.
  final String title;

  /// Detailed description explaining the detected issue.
  final String description;

  /// Severity level of the issue.
  final Severity severity;

  /// Category grouping for the issue (e.g. 'Dependencies', 'Assets').
  final String category;

  /// Path to the file associated with the issue, if applicable.
  final String? filePath;

  /// Line number in the file where the issue occurs, if applicable.
  final int? line;

  /// Column number in the file where the issue occurs, if applicable.
  final int? column;

  /// Actionable recommendation to resolve the issue.
  final String? recommendation;

  final int? _scorePenalty;

  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    this.filePath,
    this.line,
    this.column,
    this.recommendation,
    int? scorePenalty,
  }) : _scorePenalty = scorePenalty;

  /// Health score penalty points deducted for this issue.
  int get scorePenalty => _scorePenalty ?? severity.defaultPenalty;


  /// Converts issue to a JSON-serializable Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'category': category,
      if (filePath != null) 'filePath': filePath,
      if (line != null) 'line': line,
      if (column != null) 'column': column,
      if (recommendation != null) 'recommendation': recommendation,
      'scorePenalty': scorePenalty,
    };
  }

  @override
  String toString() =>
      'Issue(id: $id, title: $title, category: $category, severity: ${severity.name})';
}
