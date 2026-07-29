import 'package:flutter_audit/analyzers/dependency_analyzer.dart';
import 'package:flutter_audit/models/dart_file_info.dart';
import 'package:flutter_audit/models/directory_info.dart';
import 'package:flutter_audit/models/project.dart';
import 'package:flutter_audit/models/pubspec_info.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyAnalyzer', () {
    test('reports declared dependency that is never imported', () async {
      const pubspec = PubspecInfo(
        name: 'sample_app',
        version: '1.0.0',
        dependencies: {
          'dio': '^5.0.0',
          'provider': '^6.0.0',
          'flutter_bloc': '^8.0.0', // Unused!
        },
        devDependencies: {},
        dependencyOverrides: {},
        flutterAssets: [],
        flutterFonts: [],
        flutterPlugins: {},
        rawYaml: '',
        yamlMap: {},
      );

      // Dummy dart file importing dio and provider only
      final dartFile = DartFileInfo(
        relativePath: 'lib/main.dart',
        absolutePath: '/root/lib/main.dart',
        unit: null as dynamic,
        lineCount: 20,
        importedPackages: {'dio', 'provider'},
        imports: [],
        exports: [],
        classes: [],
        topLevelFunctions: [],
        stringLiterals: {},
        assetUsages: [],
      );

      final project = Project(
        rootPath: '/root',
        pubspec: pubspec,
        dartFiles: [dartFile],
        assets: [],
        directoryScan: const DirectoryScanResult(
          emptyDirectories: [],
          duplicateFilenames: {},
          generatedFiles: [],
          temporaryFiles: [],
          backupFiles: [],
        ),
      );

      final analyzer = DependencyAnalyzer();
      final issues = await analyzer.analyze(project);

      expect(issues.length, equals(1));
      expect(issues.first.id, equals('unused_dependency'));
      expect(issues.first.title, contains('flutter_bloc'));
      expect(issues.first.scorePenalty, equals(2));
    });
  });
}
