import '../analyzers/asset_analyzer.dart';
import '../analyzers/base_analyzer.dart';
import '../analyzers/pubspec_analyzer.dart';
import 'base_command.dart';

/// Command to scan and audit project assets.
class AssetsCommand extends BaseAuditCommand {
  @override
  final String name = 'assets';

  @override
  final String description =
      'Scans project assets for unused assets, duplicate images/files, large assets, and pubspec asset declarations.';

  @override
  List<Analyzer> getAnalyzers() {
    return [
      AssetAnalyzer(),
      PubspecAnalyzer(),
    ];
  }
}
