import 'dart:io';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import 'base_analyzer.dart';

class FlutterUpgradeAnalyzer implements Analyzer {
  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];

    try {
      final result = await Process.run('flutter', ['--version', '--machine'],
          runInShell: true);
      if (result.exitCode != 0) return issues;

      final versionInfo = result.stdout as String;
      final lines = versionInfo.split('\n');
      String? version;
      String? channel;

      for (final line in lines) {
        if (line.contains('"frameworkVersion"')) {
          version = line.split(':').last.trim().replaceAll(',', '').trim();
        }
        if (line.contains('"channel"')) {
          channel = line.split(':').last.trim().replaceAll(',', '').trim();
        }
      }

      if (version != null) {
        issues.add(Issue(
          id: 'flutter_version',
          title: 'Flutter $version ($channel)',
          description:
              'Current Flutter SDK version is $version on the $channel channel.',
          severity: Severity.info,
          category: 'Flutter',
          recommendation:
              channel == 'stable' && _isOldVersion(version)
                  ? 'Consider upgrading Flutter with "flutter upgrade" to get the latest features and fixes.'
                  : channel != 'stable'
                      ? 'Consider switching to the stable channel with "flutter channel stable".'
                      : null,
          scorePenalty: 0,
        ));

        if (channel != 'stable') {
          issues.add(Issue(
            id: 'non_stable_channel',
            title: 'Using $channel Channel Instead of stable',
            description:
                'The project is on the "$channel" Flutter channel, which may have unstable APIs.',
            severity: Severity.info,
            category: 'Flutter',
            recommendation:
                'Switch to stable with: flutter channel stable && flutter upgrade',
            scorePenalty: 1,
          ));
        }
      }

      final sdkConstraint =
          project.pubspec.yamlMap['environment']?['sdk'];
      if (sdkConstraint != null && version != null) {
        issues.add(Issue(
          id: 'sdk_constraint',
          title: 'SDK Constraint: $sdkConstraint',
          description:
              'The pubspec.yaml SDK constraint is "$sdkConstraint" with Flutter $version installed.',
          severity: Severity.info,
          category: 'Flutter',
          recommendation:
              'Ensure your SDK constraint matches your Flutter version. Run "dart --version" to check the Dart SDK.',
          scorePenalty: 0,
        ));
      }
    } catch (_) {
      issues.add(Issue(
        id: 'flutter_not_found',
        title: 'Flutter SDK Not Detected',
        description:
            'Could not run "flutter --version". Ensure Flutter is installed and in your PATH.',
        severity: Severity.warning,
        category: 'Flutter',
        recommendation:
            'Install Flutter from https://docs.flutter.dev/get-started/install',
        scorePenalty: 1,
      ));
    }

    return issues;
  }

  bool _isOldVersion(String version) {
    final parts = version.split('.');
    if (parts.length < 3) return false;
    try {
      final major = int.parse(parts[0]);
      final minor = int.parse(parts[1]);
      return major < 3 || (major == 3 && minor < 10);
    } catch (_) {
      return false;
    }
  }
}
