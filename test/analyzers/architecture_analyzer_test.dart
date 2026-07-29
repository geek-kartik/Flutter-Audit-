import 'package:flutter_audit/analyzers/architecture_analyzer.dart';
import 'package:flutter_audit/models/dart_file_info.dart';
import 'package:flutter_audit/models/directory_info.dart';
import 'package:flutter_audit/models/project.dart';
import 'package:flutter_audit/models/pubspec_info.dart';
import 'package:test/test.dart';

void main() {
  group('ArchitectureAnalyzer', () {
    const pubspec = PubspecInfo(
      name: 'my_app',
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

    test('detects unreachable unused Dart files from main.dart', () async {
      final mainFile = DartFileInfo(
        relativePath: 'lib/main.dart',
        absolutePath: '/root/lib/main.dart',
        unit: null as dynamic,
        lineCount: 20,
        importedPackages: {},
        imports: [
          const ImportDirectiveInfo(uri: 'home.dart', line: 2, column: 1),
        ],
        exports: [],
        classes: [],
        topLevelFunctions: [],
        stringLiterals: {},
        assetUsages: [],
      );

      final homeFile = DartFileInfo(
        relativePath: 'lib/home.dart',
        absolutePath: '/root/lib/home.dart',
        unit: null as dynamic,
        lineCount: 25,
        importedPackages: {},
        imports: [],
        exports: [],
        classes: [],
        topLevelFunctions: [],
        stringLiterals: {},
        assetUsages: [],
      );

      final orphanFile = DartFileInfo(
        relativePath: 'lib/old_unused_screen.dart',
        absolutePath: '/root/lib/old_unused_screen.dart',
        unit: null as dynamic,
        lineCount: 30,
        importedPackages: {},
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
        dartFiles: [mainFile, homeFile, orphanFile],
        assets: [],
        directoryScan: const DirectoryScanResult(
          emptyDirectories: [],
          duplicateFilenames: {},
          generatedFiles: [],
          temporaryFiles: [],
          backupFiles: [],
        ),
      );

      final analyzer = const ArchitectureAnalyzer();
      final issues = await analyzer.analyze(project);

      final unusedFiles = issues.where((i) => i.id == 'unused_dart_file');
      expect(unusedFiles.length, equals(1));
      expect(unusedFiles.first.filePath, equals('lib/old_unused_screen.dart'));
      expect(unusedFiles.first.scorePenalty, equals(3));
    });

    test('detects huge widgets and large classes', () async {
      final hugeWidgetClass = ClassDeclarationInfo(
        name: 'HugeWidget',
        isWidget: true,
        lineCount: 150, // > 100 maxWidgetLines
        line: 10,
        column: 1,
        methodCount: 5,
        publicMemberCount: 3,
        constructorParamCount: 2,
        maxWidgetNestingDepth: 4,
        methods: [],
      );

      final widgetFile = DartFileInfo(
        relativePath: 'lib/main.dart',
        absolutePath: '/root/lib/main.dart',
        unit: null as dynamic,
        lineCount: 180,
        importedPackages: {},
        imports: [],
        exports: [],
        classes: [hugeWidgetClass],
        topLevelFunctions: [],
        stringLiterals: {},
        assetUsages: [],
      );

      final project = Project(
        rootPath: '/root',
        pubspec: pubspec,
        dartFiles: [widgetFile],
        assets: [],
        directoryScan: const DirectoryScanResult(
          emptyDirectories: [],
          duplicateFilenames: {},
          generatedFiles: [],
          temporaryFiles: [],
          backupFiles: [],
        ),
      );

      final analyzer = const ArchitectureAnalyzer();
      final issues = await analyzer.analyze(project);

      final largeWidgets = issues.where((i) => i.id == 'large_widget');
      expect(largeWidgets.length, equals(1));
      expect(largeWidgets.first.title, contains('HugeWidget'));
    });
  });
}
