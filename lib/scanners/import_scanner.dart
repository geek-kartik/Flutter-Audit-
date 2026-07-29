import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import '../models/dart_file_info.dart';

/// Standalone helper scanner for parsing import and export directives from raw Dart code string.
class ImportScanner {
  /// Extracts list of [ImportDirectiveInfo] from Dart source [content].
  List<ImportDirectiveInfo> extractImports(String content) {
    try {
      final parseResult = parseString(
        content: content,
        throwIfDiagnostics: false,
      );
      final visitor = _DirectiveVisitor(parseResult.unit.lineInfo);
      parseResult.unit.visitChildren(visitor);
      return visitor.imports;
    } catch (_) {
      return [];
    }
  }

  /// Extracts list of [ExportDirectiveInfo] from Dart source [content].
  List<ExportDirectiveInfo> extractExports(String content) {
    try {
      final parseResult = parseString(
        content: content,
        throwIfDiagnostics: false,
      );
      final visitor = _DirectiveVisitor(parseResult.unit.lineInfo);
      parseResult.unit.visitChildren(visitor);
      return visitor.exports;
    } catch (_) {
      return [];
    }
  }
}

class _DirectiveVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;
  final List<ImportDirectiveInfo> imports = [];
  final List<ExportDirectiveInfo> exports = [];

  _DirectiveVisitor(this.lineInfo);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    final loc = lineInfo.getLocation(node.offset);
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
}
