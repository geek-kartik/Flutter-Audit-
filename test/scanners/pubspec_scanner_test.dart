import 'dart:io';
import 'package:flutter_audit/scanners/pubspec_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PubspecScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pubspec_scanner_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('parses valid pubspec.yaml with assets and fonts', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: my_sample_app
version: 1.2.3
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  provider: ^6.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
dependency_overrides:
  dio: 5.1.0

flutter:
  assets:
    - assets/images/logo.png
    - assets/icons/
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
''');

      final scanner = PubspecScanner();
      final result = await scanner.scan(tempDir.path);

      expect(result.name, equals('my_sample_app'));
      expect(result.version, equals('1.2.3'));
      expect(result.dependencies.containsKey('dio'), isTrue);
      expect(result.dependencies.containsKey('provider'), isTrue);
      expect(result.devDependencies.containsKey('build_runner'), isTrue);
      expect(result.dependencyOverrides.containsKey('dio'), isTrue);
      expect(result.flutterAssets, contains('assets/images/logo.png'));
      expect(result.flutterAssets, contains('assets/icons/'));
      expect(result.flutterFonts.length, equals(1));
      expect(result.flutterFonts.first.family, equals('CustomFont'));
      expect(
        result.flutterFonts.first.assetPaths,
        contains('assets/fonts/CustomFont-Regular.ttf'),
      );
    });

    test('returns default PubspecInfo when pubspec.yaml is missing', () async {
      final scanner = PubspecScanner();
      final result = await scanner.scan(tempDir.path);

      expect(result.name, equals('unknown'));
      expect(result.dependencies, isEmpty);
      expect(result.flutterAssets, isEmpty);
    });
  });
}
