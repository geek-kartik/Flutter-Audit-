import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// Information extracted from a single Dart source file.
@immutable
class DartFileInfo {
  /// Relative path of the Dart file (e.g. 'lib/main.dart').
  final String relativePath;

  /// Absolute path of the Dart file.
  final String absolutePath;

  /// Parsed compilation unit AST root node.
  final CompilationUnit? unit;


  /// Total number of lines in the file.
  final int lineCount;

  /// Package names imported in this file (e.g. 'dio', 'provider').
  final Set<String> importedPackages;

  /// Detailed import directives with URI, line, column, and raw string.
  final List<ImportDirectiveInfo> imports;

  /// Detailed export directives with URI, line, column, and raw string.
  final List<ExportDirectiveInfo> exports;

  /// Classes declared in this file.
  final List<ClassDeclarationInfo> classes;

  /// Top-level functions declared in this file.
  final List<FunctionDeclarationInfo> topLevelFunctions;

  /// String literal contents found anywhere in the file AST.
  final Set<String> stringLiterals;

  /// Asset usage locations detected via widget/AST analysis.
  final List<AssetUsageInfo> assetUsages;

  const DartFileInfo({
    required this.relativePath,
    required this.absolutePath,
    required this.unit,
    required this.lineCount,
    required this.importedPackages,
    required this.imports,
    required this.exports,
    required this.classes,
    required this.topLevelFunctions,
    required this.stringLiterals,
    required this.assetUsages,
  });
}

/// Information about an import directive.
@immutable
class ImportDirectiveInfo {
  final String uri;
  final int line;
  final int column;

  const ImportDirectiveInfo({
    required this.uri,
    required this.line,
    required this.column,
  });
}

/// Information about an export directive.
@immutable
class ExportDirectiveInfo {
  final String uri;
  final int line;
  final int column;

  const ExportDirectiveInfo({
    required this.uri,
    required this.line,
    required this.column,
  });
}

/// Information about a class declared in a Dart file.
@immutable
class ClassDeclarationInfo {
  final String name;
  final bool isWidget;
  final int lineCount;
  final int line;
  final int column;
  final int methodCount;
  final int publicMemberCount;
  final int constructorParamCount;
  final int maxWidgetNestingDepth;
  final List<MethodDeclarationInfo> methods;

  const ClassDeclarationInfo({
    required this.name,
    required this.isWidget,
    required this.lineCount,
    required this.line,
    required this.column,
    required this.methodCount,
    required this.publicMemberCount,
    required this.constructorParamCount,
    required this.maxWidgetNestingDepth,
    required this.methods,
  });
}

/// Information about a method declaration inside a class.
@immutable
class MethodDeclarationInfo {
  final String name;
  final int lineCount;
  final int line;
  final int column;
  final int parameterCount;
  final int maxWidgetNestingDepth;

  const MethodDeclarationInfo({
    required this.name,
    required this.lineCount,
    required this.line,
    required this.column,
    required this.parameterCount,
    required this.maxWidgetNestingDepth,
  });
}

/// Information about a top-level function.
@immutable
class FunctionDeclarationInfo {
  final String name;
  final int lineCount;
  final int line;
  final int column;

  const FunctionDeclarationInfo({
    required this.name,
    required this.lineCount,
    required this.line,
    required this.column,
  });
}

/// Information about an asset reference detected in AST.
@immutable
class AssetUsageInfo {
  final String assetPathOrName;
  final String usageContext; // e.g. 'Image.asset', 'AssetImage', 'String'
  final int line;
  final int column;

  const AssetUsageInfo({
    required this.assetPathOrName,
    required this.usageContext,
    required this.line,
    required this.column,
  });
}
