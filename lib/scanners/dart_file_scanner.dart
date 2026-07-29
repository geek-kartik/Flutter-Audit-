import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import '../models/dart_file_info.dart';
import '../utils/extensions.dart';

/// Scanner for parsing Dart files and building AST metadata.
class DartFileScanner {
  /// Scans all `.dart` files in the project (under `lib/`, `test/`, `bin/`).
  Future<List<DartFileInfo>> scan(String projectPath) async {
    final root = p.canonicalize(projectPath);
    final results = <DartFileInfo>[];
    final searchDirs = ['lib', 'test', 'bin'];

    for (final dirName in searchDirs) {
      final dir = Directory(p.join(root, dirName));
      if (!dir.existsSync()) continue;


      try {
        final entities = dir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File || FileSystemEntity.isFileSync(entity.path)) {
            if (entity.path.endsWith('.dart')) {
              final info = await scanFile(entity.path, root);

              if (info != null) {
                results.add(info);
              }
            }
          }
        }
      } catch (_) {}

    }

    return results;
  }



  /// Scans a single Dart file at [filePath].
  Future<DartFileInfo?> scanFile(String filePath, String projectPath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final parseResult = parseString(
        content: content,
        throwIfDiagnostics: false,
      );

      final unit = parseResult.unit;
      final lineInfo = unit.lineInfo;
      final lines = content.split('\n');
      final lineCount = lines.length;

      final visitor = _DartAstVisitor(lineInfo: lineInfo);
      unit.visitChildren(visitor);

      final relPath = filePath.toRelativePath(projectPath);

      return DartFileInfo(
        relativePath: relPath,
        absolutePath: filePath.normalizePath(),
        unit: unit,
        lineCount: lineCount,
        importedPackages: visitor.importedPackages,
        imports: visitor.imports,
        exports: visitor.exports,
        classes: visitor.classes,
        topLevelFunctions: visitor.topLevelFunctions,
        stringLiterals: visitor.stringLiterals,
        assetUsages: visitor.assetUsages,
      );
    } catch (_) {
      return null;
    }



  }
}

class _DartAstVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;

  final Set<String> importedPackages = {};
  final List<ImportDirectiveInfo> imports = [];
  final List<ExportDirectiveInfo> exports = [];
  final List<ClassDeclarationInfo> classes = [];
  final List<FunctionDeclarationInfo> topLevelFunctions = [];
  final Set<String> stringLiterals = {};
  final List<AssetUsageInfo> assetUsages = [];

  _DartAstVisitor({required this.lineInfo});

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    final loc = lineInfo.getLocation(node.offset);

    if (uri.startsWith('package:')) {
      final parts = uri.substring('package:'.length).split('/');
      if (parts.isNotEmpty) {
        importedPackages.add(parts.first);
      }
    }

    imports.add(ImportDirectiveInfo(
      uri: uri,
      line: loc.lineNumber,
      column: loc.columnNumber,
    ));

    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    final uri = node.uri.stringValue ?? '';
    final loc = lineInfo.getLocation(node.offset);

    exports.add(ExportDirectiveInfo(
      uri: uri,
      line: loc.lineNumber,
      column: loc.columnNumber,
    ));

    super.visitExportDirective(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final val = node.value;
    if (val.isNotEmpty) {
      stringLiterals.add(val);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final buf = StringBuffer();
    for (final element in node.elements) {
      if (element is InterpolationString) {
        buf.write(element.value);
      }
    }
    final str = buf.toString();
    if (str.isNotEmpty) {
      stringLiterals.add(str);
    }
    super.visitStringInterpolation(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Only process top-level functions here (parent is CompilationUnit)
    if (node.parent is CompilationUnit) {
      final startLoc = lineInfo.getLocation(node.offset);
      final endLoc = lineInfo.getLocation(node.endToken.offset);
      final lCount = endLoc.lineNumber - startLoc.lineNumber + 1;

      topLevelFunctions.add(FunctionDeclarationInfo(
        name: node.name.lexeme,
        lineCount: lCount,
        line: startLoc.lineNumber,
        column: startLoc.columnNumber,
      ));
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final startLoc = lineInfo.getLocation(node.offset);
    final endLoc = lineInfo.getLocation(node.endToken.offset);
    final lCount = endLoc.lineNumber - startLoc.lineNumber + 1;

    final superName = node.extendsClause?.superclass.name2.lexeme ?? '';
    final isWidget = _isWidgetSuperclass(superName);

    int methodCount = 0;
    int publicMemberCount = 0;
    int constructorParamCount = 0;
    final methodInfos = <MethodDeclarationInfo>[];
    int maxNestingDepthInClass = 0;

    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        final pCount = member.parameters.parameters.length;
        if (pCount > constructorParamCount) {
          constructorParamCount = pCount;
        }
      } else if (member is MethodDeclaration) {
        methodCount++;
        if (!member.name.lexeme.startsWith('_')) {
          publicMemberCount++;
        }

        final mStart = lineInfo.getLocation(member.offset);
        final mEnd = lineInfo.getLocation(member.endToken.offset);
        final mLines = mEnd.lineNumber - mStart.lineNumber + 1;

        final nesting = _computeMaxNesting(member.body);
        if (nesting > maxNestingDepthInClass) {
          maxNestingDepthInClass = nesting;
        }

        methodInfos.add(MethodDeclarationInfo(
          name: member.name.lexeme,
          lineCount: mLines,
          line: mStart.lineNumber,
          column: mStart.columnNumber,
          parameterCount: member.parameters?.parameters.length ?? 0,
          maxWidgetNestingDepth: nesting,
        ));
      } else if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (!variable.name.lexeme.startsWith('_')) {
            publicMemberCount++;
          }
        }
      }
    }

    classes.add(ClassDeclarationInfo(
      name: node.name.lexeme,
      isWidget: isWidget,
      lineCount: lCount,
      line: startLoc.lineNumber,
      column: startLoc.columnNumber,
      methodCount: methodCount,
      publicMemberCount: publicMemberCount,
      constructorParamCount: constructorParamCount,
      maxWidgetNestingDepth: maxNestingDepthInClass,
      methods: methodInfos,
    ));

    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final targetStr = node.target?.toString() ?? '';
    final methodStr = node.methodName.name;
    final fullName = targetStr.isNotEmpty ? '$targetStr.$methodStr' : methodStr;

    _checkAndAddAssetUsage(fullName, node.argumentList, node.offset);

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.toString();
    _checkAndAddAssetUsage(constructorName, node.argumentList, node.offset);

    super.visitInstanceCreationExpression(node);
  }

  void _checkAndAddAssetUsage(
    String name,
    ArgumentList argumentList,
    int offset,
  ) {
    if (name.contains('Image.asset') ||
        name.contains('AssetImage') ||
        name.contains('ExactAssetImage') ||
        name.contains('SvgPicture.asset') ||
        name.contains('DecorationImage') ||
        name.contains('FadeInImage.assetNetwork')) {
      final args = argumentList.arguments;
      if (args.isNotEmpty) {
        final firstArg = args.first;
        String? assetStr;
        if (firstArg is SimpleStringLiteral) {
          assetStr = firstArg.value;
        } else if (firstArg is StringInterpolation) {
          final buf = StringBuffer();
          for (final el in firstArg.elements) {
            if (el is InterpolationString) buf.write(el.value);
          }
          assetStr = buf.toString();
        }

        if (assetStr != null && assetStr.isNotEmpty) {
          final loc = lineInfo.getLocation(offset);
          assetUsages.add(AssetUsageInfo(
            assetPathOrName: assetStr,
            usageContext: name,
            line: loc.lineNumber,
            column: loc.columnNumber,
          ));
        }
      }
    }
  }


  bool _isWidgetSuperclass(String superName) {
    return superName == 'StatelessWidget' ||
        superName == 'StatefulWidget' ||
        superName == 'State' ||
        superName == 'InheritedWidget' ||
        superName == 'ConsumerWidget' ||
        superName == 'HookWidget' ||
        superName == 'Widget';
  }

  int _computeMaxNesting(AstNode node) {
    final visitor = _NestingVisitor();
    node.visitChildren(visitor);
    return visitor.maxDepth;
  }
}

class _NestingVisitor extends RecursiveAstVisitor<void> {
  int currentDepth = 0;
  int maxDepth = 0;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    currentDepth++;
    if (currentDepth > maxDepth) {
      maxDepth = currentDepth;
    }
    super.visitInstanceCreationExpression(node);
    currentDepth--;
  }
}
