import 'package:flutter_audit/analyzers/asset_analyzer.dart';
import 'package:flutter_audit/models/asset_info.dart';
import 'package:flutter_audit/models/dart_file_info.dart';
import 'package:flutter_audit/models/directory_info.dart';
import 'package:flutter_audit/models/project.dart';
import 'package:flutter_audit/models/pubspec_info.dart';
import 'package:test/test.dart';

void main() {
  group('AssetAnalyzer', () {
    const pubspec = PubspecInfo(
      name: 'test_app',
      version: '1.0.0',
      dependencies: {},
      devDependencies: {},
      dependencyOverrides: {},
      flutterAssets: [],
      flutterFonts: [],
      flutterPlugins: {},
      rawYaml: '',
      yamlMap: {},
    );

    test('detects unused assets, duplicate assets, and large images', () async {
      const asset1 = AssetInfo(
        relativePath: 'assets/images/unused.png',
        absolutePath: '/root/assets/images/unused.png',
        sizeInBytes: 600 * 1024, // > 500 KB large image
        extension: '.png',
        sha256Hash: 'hash123456789',
      );

      const asset2 = AssetInfo(
        relativePath: 'assets/images/dup1.png',
        absolutePath: '/root/assets/images/dup1.png',
        sizeInBytes: 100 * 1024,
        extension: '.png',
        sha256Hash: 'same_hash_abc',
      );

      const asset3 = AssetInfo(
        relativePath: 'assets/images/dup2.png',
        absolutePath: '/root/assets/images/dup2.png',
        sizeInBytes: 100 * 1024,
        extension: '.png',
        sha256Hash: 'same_hash_abc', // Duplicate of asset2!
      );

      final dartFile = DartFileInfo(
        relativePath: 'lib/main.dart',
        absolutePath: '/root/lib/main.dart',
        unit: null as dynamic,
        lineCount: 30,
        importedPackages: {},
        imports: [],
        exports: [],
        classes: [],
        topLevelFunctions: [],
        stringLiterals: {'assets/images/dup1.png'},
        assetUsages: [],
      );

      final project = Project(
        rootPath: '/root',
        pubspec: pubspec,
        dartFiles: [dartFile],
        assets: [asset1, asset2, asset3],
        directoryScan: const DirectoryScanResult(
          emptyDirectories: [],
          duplicateFilenames: {},
          generatedFiles: [],
          temporaryFiles: [],
          backupFiles: [],
        ),
      );

      final analyzer = const AssetAnalyzer();
      final issues = await analyzer.analyze(project);

      final unusedIssue = issues.where((i) => i.id == 'unused_asset');
      final largeIssue = issues.where((i) => i.id == 'large_image');
      final duplicateIssue = issues.where((i) => i.id == 'duplicate_asset');

      expect(unusedIssue.length, equals(2));

      expect(unusedIssue.first.filePath, equals('assets/images/unused.png'));

      expect(largeIssue.length, equals(1));
      expect(largeIssue.first.filePath, equals('assets/images/unused.png'));

      expect(duplicateIssue.length, equals(1));
      expect(duplicateIssue.first.scorePenalty, equals(2));
    });
  });
}
