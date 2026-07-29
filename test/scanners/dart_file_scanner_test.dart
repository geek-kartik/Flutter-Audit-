import 'dart:io';
import 'package:flutter_audit/scanners/dart_file_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DartFileScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_scanner_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scans dart file AST, packages, widgets, and line counts', () async {
      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync(recursive: true);
      final file = File(p.join(libDir.path, 'main.dart'));

      await file.writeAsString('''
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Image.asset('assets/images/logo.png'),
    );
  }
}
''');

      final canonicalPath = p.canonicalize(tempDir.path);
      final scanner = DartFileScanner();

      final singleInfo = await scanner.scanFile(p.join(canonicalPath, 'lib', 'main.dart'), canonicalPath);
      expect(singleInfo, isNotNull);

      final results = await scanner.scan(canonicalPath);
      expect(results.length, equals(1));
      final info = results.first;

      expect(info.importedPackages, containsAll(['flutter', 'dio', 'provider']));
      expect(info.classes.length, equals(1));
      expect(info.classes.first.name, equals('MyApp'));
      expect(info.classes.first.isWidget, isTrue);
      expect(info.stringLiterals, contains('assets/images/logo.png'));
      expect(info.assetUsages.length, equals(1));
      expect(info.assetUsages.first.assetPathOrName, equals('assets/images/logo.png'));
    });
  });
}
