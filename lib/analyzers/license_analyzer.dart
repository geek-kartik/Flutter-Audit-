import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import 'base_analyzer.dart';

class LicenseAnalyzer implements Analyzer {
  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];
    final rootPath = project.rootPath;

    final hasLicenseFile = File(p.join(rootPath, 'LICENSE')).existsSync() ||
        File(p.join(rootPath, 'LICENSE.md')).existsSync() ||
        File(p.join(rootPath, 'LICENSE.txt')).existsSync();

    if (!hasLicenseFile) {
      issues.add(Issue(
        id: 'missing_project_license',
        title: 'Missing Project License File',
        description:
            'No LICENSE file found in the project root. Open source projects should include a license.',
        severity: Severity.info,
        category: 'Licenses',
        filePath: 'pubspec.yaml',
        recommendation:
            'Add a LICENSE file (e.g. MIT, Apache 2.0, GPL) to your project root.',
        scorePenalty: 1,
      ));
    }

    final allDeps = {
      ...project.pubspec.dependencies,
      ...project.pubspec.devDependencies,
    };

    final pubCachePath = _findPubCache();
    final missingLicenseDeps = <String>[];

    if (pubCachePath != null) {
      for (final dep in allDeps.keys) {
        if (_isKnownSdkPackage(dep)) continue;
        final depPubspecPath = p.join(
          pubCachePath,
          'hosted',
          'pub.dev',
          '$dep-${allDeps[dep]}',
          'pubspec.yaml',
        );
        final depFile = File(depPubspecPath);
        if (depFile.existsSync()) {
          try {
            final content = await depFile.readAsString();
            final parsed = loadYaml(content);
            if (parsed is Map && parsed['license'] == null) {
              missingLicenseDeps.add(dep);
            }
          } catch (_) {
            missingLicenseDeps.add(dep);
          }
        } else {
          missingLicenseDeps.add('$dep (not in pub cache)');
        }
      }
    }

    if (missingLicenseDeps.isNotEmpty) {
      issues.add(Issue(
        id: 'dependencies_without_license',
        title:
            '${missingLicenseDeps.length} Dependencies Without Declared Licenses',
        description:
            'The following packages do not declare a license field in their pubspec: ${missingLicenseDeps.join(", ")}.',
        severity: Severity.info,
        category: 'Licenses',
        filePath: 'pubspec.yaml',
        recommendation:
            'Run "flutter pub deps --licenses" to review all dependency licenses and ensure compliance.',
        scorePenalty: 1,
      ));
    }

    return issues;
  }

  String? _findPubCache() {
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    final defaultCache = p.join(home, '.pub-cache');
    if (Directory(defaultCache).existsSync()) return defaultCache;
    final flutterCache = p.join(home, '.pub-cache', 'hosted');
    if (Directory(flutterCache).existsSync()) return p.join(home, '.pub-cache');
    return null;
  }

  bool _isKnownSdkPackage(String name) {
    return const {
      'flutter',
      'flutter_test',
      'flutter_driver',
      'integration_test',
      'sky_engine',
    }.contains(name);
  }
}
