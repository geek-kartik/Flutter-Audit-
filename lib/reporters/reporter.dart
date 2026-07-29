import 'dart:io';
import '../models/report.dart';

/// Abstract reporter interface for rendering project audit results.
abstract class Reporter {
  /// Renders the [Report] to [sink] or default output stream.
  void report(Report report, {IOSink? sink});
}
