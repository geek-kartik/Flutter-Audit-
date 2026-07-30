import 'dart:io';
import '../models/report.dart';
import 'reporter.dart';

class CsvReporter implements Reporter {
  const CsvReporter();

  @override
  void report(Report report, {IOSink? sink}) {
    final csv = StringBuffer();

    csv.writeln('Severity,Issue,File,Line,Column,Recommendation');

    for (final issue in report.issues) {
      csv.writeln([
        _escape(issue.severity.label),
        _escape(issue.title),
        _escape(issue.filePath ?? ''),
        issue.line?.toString() ?? '',
        issue.column?.toString() ?? '',
        _escape(issue.recommendation ?? ''),
      ].join(','));
    }

    final output = sink ?? stdout;
    output.writeln(csv.toString());
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
