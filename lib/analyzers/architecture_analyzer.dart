import 'package:path/path.dart' as p;
import '../models/dart_file_info.dart';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/severity.dart';
import '../utils/config.dart';
import '../utils/extensions.dart';
import 'base_analyzer.dart';

/// Analyzer for code architecture, component metrics, import graphs, and unused files.
class ArchitectureAnalyzer implements Analyzer {
  final AuditConfig config;

  const ArchitectureAnalyzer({this.config = const AuditConfig()});

  @override
  Future<List<Issue>> analyze(Project project) async {
    final issues = <Issue>[];

    // Map files by normalized relative path
    final fileMap = <String, DartFileInfo>{};
    for (final f in project.dartFiles) {
      fileMap[f.relativePath] = f;
    }

    // 1. UNUSED DART FILES (Import Graph BFS/DFS)
    final entryPoints = <String>[];
    if (fileMap.containsKey('lib/main.dart')) {
      entryPoints.add('lib/main.dart');
    }
    // Add any bin/*.dart or test/*.dart or root lib files that act as entrypoints
    for (final path in fileMap.keys) {
      if (path.startsWith('bin/') || path.startsWith('test/')) {
        entryPoints.add(path);
      }
    }
    // If lib/main.dart does not exist, treat all top-level lib files as entrypoints
    if (entryPoints.isEmpty) {
      for (final path in fileMap.keys) {
        if (path.startsWith('lib/')) entryPoints.add(path);
      }
    }

    final reachable = <String>{};
    final queue = List<String>.from(entryPoints);

    while (queue.isNotEmpty) {
      final currentPath = queue.removeLast();
      if (!reachable.add(currentPath)) continue;

      final fileInfo = fileMap[currentPath];
      if (fileInfo == null) continue;

      // Extract resolved relative paths for imports and exports
      for (final imp in fileInfo.imports) {
        final target = _resolveUri(imp.uri, currentPath, project.pubspec.name);
        if (target != null && fileMap.containsKey(target) && !reachable.contains(target)) {
          queue.add(target);
        }
      }
      for (final exp in fileInfo.exports) {
        final target = _resolveUri(exp.uri, currentPath, project.pubspec.name);
        if (target != null && fileMap.containsKey(target) && !reachable.contains(target)) {
          queue.add(target);
        }
      }
    }

    // Report files in lib/ not reachable from entrypoints
    for (final file in project.dartFiles) {
      if (file.relativePath.startsWith('lib/') &&
          !reachable.contains(file.relativePath) &&
          !file.relativePath.endsWith('.g.dart') &&
          !file.relativePath.endsWith('.freezed.dart')) {
        issues.add(Issue(
          id: 'unused_dart_file',
          title: 'Unused Dart File: ${file.relativePath}',
          description:
              'File "${file.relativePath}" is not imported directly or indirectly from lib/main.dart or any entry point.',
          severity: Severity.warning,
          category: 'Architecture',
          filePath: file.relativePath,
          line: 1,
          recommendation:
              'Remove "${file.relativePath}" or import it in your application dependency graph.',
          scorePenalty: 3,
        ));
      }
    }

    // 2. DUPLICATE IMPORTS & UNUSED EXPORTS & CODE METRICS
    final allImportedUris = <String>{};

    for (final file in project.dartFiles) {
      // Duplicate imports check
      final seenImports = <String, int>{};
      for (final imp in file.imports) {
        seenImports[imp.uri] = (seenImports[imp.uri] ?? 0) + 1;
        final resolved = _resolveUri(imp.uri, file.relativePath, project.pubspec.name);
        if (resolved != null) {
          allImportedUris.add(resolved);
        }
      }

      seenImports.forEach((uri, count) {
        if (count > 1) {
          issues.add(Issue(
            id: 'duplicate_import',
            title: 'Duplicate Import in ${file.relativePath}',
            description:
                'URI "$uri" is imported $count times in "${file.relativePath}".',
            severity: Severity.info,
            category: 'Architecture',
            filePath: file.relativePath,
            recommendation: 'Remove duplicate import directive.',
            scorePenalty: 1,
          ));
        }
      });

      // Large file check
      if (file.lineCount > config.maxFileLines) {
        issues.add(Issue(
          id: 'large_file',
          title: 'Large File: ${file.relativePath} (${file.lineCount} lines)',
          description:
              'File contains ${file.lineCount} lines, exceeding the max recommendation of ${config.maxFileLines} lines.',
          severity: Severity.warning,
          category: 'Architecture',
          filePath: file.relativePath,
          line: 1,
          recommendation:
              'Decompose this file into smaller, single-responsibility files.',
          scorePenalty: 2,
        ));
      }

      // Class-level architecture metrics
      for (final cls in file.classes) {
        if (cls.isWidget && cls.lineCount > config.maxWidgetLines) {
          issues.add(Issue(
            id: 'large_widget',
            title: 'Huge Widget: ${cls.name} in ${file.relativePath} (${cls.lineCount} lines)',
            description:
                'Widget class "${cls.name}" is ${cls.lineCount} lines long (max recommended: ${config.maxWidgetLines}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
              'Refactor widget into smaller modular sub-widgets.',
            scorePenalty: 2,
          ));
        } else if (!cls.isWidget && cls.lineCount > config.maxClassLines) {
          issues.add(Issue(
            id: 'large_class',
            title: 'Large Class: ${cls.name} in ${file.relativePath} (${cls.lineCount} lines)',
            description:
                'Class "${cls.name}" is ${cls.lineCount} lines long (max recommended: ${config.maxClassLines}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation: 'Break down class into smaller dedicated services.',
            scorePenalty: 2,
          ));
        }

        if (cls.constructorParamCount > config.maxConstructorParams) {
          issues.add(Issue(
            id: 'too_many_constructor_params',
            title: 'Excessive Constructor Parameters: ${cls.name}',
            description:
                'Constructor for "${cls.name}" has ${cls.constructorParamCount} parameters (max recommended: ${config.maxConstructorParams}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
                'Group related constructor parameters into parameter objects.',
            scorePenalty: 1,
          ));
        }

        if (cls.methodCount > config.maxMethodsPerClass) {
          issues.add(Issue(
            id: 'too_many_methods',
            title: 'Too Many Methods: ${cls.name} (${cls.methodCount} methods)',
            description:
                'Class "${cls.name}" defines ${cls.methodCount} methods (max recommended: ${config.maxMethodsPerClass}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
                'Extract helper methods into extension methods or separate classes.',
            scorePenalty: 1,
          ));
        }

        if (cls.publicMemberCount > config.maxPublicMembers) {
          issues.add(Issue(
            id: 'too_many_public_members',
            title: 'Too Many Public Members: ${cls.name} (${cls.publicMemberCount} public members)',
            description:
                'Class "${cls.name}" exposes ${cls.publicMemberCount} public members (max recommended: ${config.maxPublicMembers}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
                'Encapsulate internal fields and methods as private (_).',
            scorePenalty: 1,
          ));
        }

        if (cls.maxWidgetNestingDepth > config.maxWidgetNestingDepth) {
          issues.add(Issue(
            id: 'excessive_widget_nesting',
            title: 'Excessive Widget Nesting in ${cls.name} (depth: ${cls.maxWidgetNestingDepth})',
            description:
                'Widget tree nesting depth is ${cls.maxWidgetNestingDepth} levels (max recommended: ${config.maxWidgetNestingDepth}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: cls.line,
            column: cls.column,
            recommendation:
                'Flatten widget tree hierarchy by extracting custom sub-widgets.',
            scorePenalty: 2,
          ));
        }

        // Method line count check
        for (final m in cls.methods) {
          if (m.lineCount > config.maxFunctionLines) {
            issues.add(Issue(
              id: 'large_function',
              title: 'Large Method: ${cls.name}.${m.name} (${m.lineCount} lines)',
              description:
                  'Method "${m.name}" in class "${cls.name}" is ${m.lineCount} lines long (max recommended: ${config.maxFunctionLines}).',
              severity: Severity.warning,
              category: 'Architecture',
              filePath: file.relativePath,
              line: m.line,
              column: m.column,
              recommendation:
                  'Extract method sub-steps into helper functions.',
              scorePenalty: 1,
            ));
          }
        }
      }

      // Top-level function line count check
      for (final fn in file.topLevelFunctions) {
        if (fn.lineCount > config.maxFunctionLines) {
          issues.add(Issue(
            id: 'large_function',
            title: 'Large Function: ${fn.name} (${fn.lineCount} lines)',
            description:
                'Top-level function "${fn.name}" is ${fn.lineCount} lines long (max recommended: ${config.maxFunctionLines}).',
            severity: Severity.warning,
            category: 'Architecture',
            filePath: file.relativePath,
            line: fn.line,
            column: fn.column,
            recommendation: 'Extract sub-logic into helper functions.',
            scorePenalty: 1,
          ));
        }
      }
    }

    // 3. UNUSED EXPORTS
    for (final file in project.dartFiles) {
      for (final exp in file.exports) {
        final resolved = _resolveUri(exp.uri, file.relativePath, project.pubspec.name);
        if (resolved != null && fileMap.containsKey(resolved)) {
          if (!allImportedUris.contains(resolved) && !entryPoints.contains(file.relativePath)) {
            issues.add(Issue(
              id: 'unused_export',
              title: 'Unused Export in ${file.relativePath}',
              description:
                  'Export statement "${exp.uri}" points to a file that is never imported elsewhere in the project.',
              severity: Severity.info,
              category: 'Architecture',
              filePath: file.relativePath,
              line: exp.line,
              column: exp.column,
              recommendation: 'Remove unused export statement.',
              scorePenalty: 1,
            ));
          }
        }
      }
    }

    return issues;
  }

  String? _resolveUri(String uri, String currentFilePath, String packageName) {
    if (uri.startsWith('package:$packageName/')) {
      final sub = uri.substring('package:$packageName/'.length);
      return 'lib/$sub'.normalizePath();
    } else if (uri.startsWith('package:')) {
      return null; // External package import
    } else if (uri.startsWith('dart:')) {
      return null; // Core Dart import
    } else {
      // Relative import
      final dir = p.dirname(currentFilePath);
      final resolved = p.join(dir, uri);
      return resolved.normalizePath();
    }
  }
}
