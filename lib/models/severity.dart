import 'package:meta/meta.dart';

/// Represents the severity level of an audited issue.
@immutable
enum Severity {
  /// Informational note with minimal score impact.
  info,

  /// Warning about sub-optimal pattern or minor issue.
  warning,

  /// Critical issue or violation requiring immediate attention.
  error;

  /// Default health score deduction for this severity level.
  int get defaultPenalty {
    switch (this) {
      case Severity.info:
        return 1;
      case Severity.warning:
        return 2;
      case Severity.error:
        return 3;
    }
  }

  /// Display label for reporting.
  String get label {
    switch (this) {
      case Severity.info:
        return 'INFO';
      case Severity.warning:
        return 'WARNING';
      case Severity.error:
        return 'ERROR';
    }
  }
}
