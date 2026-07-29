import 'dart:convert';
import 'dart:io';
import '../models/report.dart';
import 'reporter.dart';

/// Reporter that formats output as structured JSON.
class JsonReporter implements Reporter {
  const JsonReporter();

  @override
  void report(Report report, {IOSink? sink}) {
    final jsonMap = report.toJson();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);

    if (sink != null) {
      sink.writeln(jsonStr);
    } else {
      // ignore: avoid_print
      print(jsonStr);
    }
  }
}
