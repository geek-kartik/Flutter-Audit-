import '../models/issue.dart';
import '../models/project.dart';

/// Abstract contract for extensible project audit analyzers.
abstract class Analyzer {
  /// Analyzes the target [Project] and returns a list of detected [Issue]s.
  Future<List<Issue>> analyze(Project project);
}
