import 'dart:io';
import 'package:flutter_audit/commands/audit_command.dart';
import 'package:flutter_audit/scanners/asset_scanner.dart';
import 'package:flutter_audit/scanners/dart_file_scanner.dart';
import 'package:flutter_audit/scanners/directory_scanner.dart';
import 'package:flutter_audit/scanners/pubspec_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CLI End-to-End Integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('flutter_audit_integration_');

      // Create mock project structure
      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync(recursive: true);
      final assetsDir = Directory(p.join(tempDir.path, 'assets', 'images'))..createSync(recursive: true);

      // Write pubspec.yaml
      await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: integration_sample
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  provider: ^6.0.0
  flutter_bloc: ^8.0.0 # Unused dependency

flutter:
  assets:
    - assets/images/logo.png
    - assets/images/unused.png
''');

      // Write lib/main.dart
      await File(p.join(libDir.path, 'main.dart')).writeAsString('''
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'home.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}
''');

      // Write lib/home.dart
      await File(p.join(libDir.path, 'home.dart')).writeAsString('''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo.png');
  }
}
''');

      // Write lib/orphan.dart (Unused Dart File)
      await File(p.join(libDir.path, 'orphan.dart')).writeAsString('''
class OrphanScreen {}
''');

      // Write physical assets
      await File(p.join(assetsDir.path, 'logo.png')).writeAsString('sample logo binary data');
      await File(p.join(assetsDir.path, 'unused.png')).writeAsString('sample unused binary data');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scans project correctly and identifies unused dependencies, assets, and files', () async {
      final pubspec = await PubspecScanner().scan(tempDir.path);
      final assets = await AssetScanner().scan(tempDir.path, pubspec);
      final dartFiles = await DartFileScanner().scan(tempDir.path);
      final dirScan = await DirectoryScanner().scan(tempDir.path);

      expect(pubspec.name, equals('integration_sample'));
      expect(assets.length, equals(2));
      expect(dartFiles.length, equals(3));

      final auditCommand = AuditCommand();
      final runner = auditCommand.getAnalyzers();

      expect(runner.length, equals(8));
    });
  });
}
