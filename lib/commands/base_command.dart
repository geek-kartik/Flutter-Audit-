import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../analyzers/base_analyzer.dart';
import '../models/issue.dart';
import '../models/project.dart';
import '../models/report.dart';
import '../reporters/console_reporter.dart';
import '../reporters/json_reporter.dart';
import '../reporters/markdown_reporter.dart';
import '../scanners/asset_scanner.dart';
import '../scanners/dart_file_scanner.dart';
import '../scanners/directory_scanner.dart';
import '../scanners/pubspec_scanner.dart';
import '../utils/logger.dart';

/// Base command providing common project scanning, execution, and reporting logic.
abstract class BaseAuditCommand extends Command<int> {
  BaseAuditCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Path to the Flutter project root directory.',
      defaultsTo: '.',
    );
    argParser.addFlag(
      'json',
      abbr: 'j',
      help: 'Output report in JSON format.',
      negatable: false,
    );
    argParser.addFlag(
      'markdown',
      abbr: 'm',
      help: 'Generate Markdown audit report.',
      negatable: false,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'File path to write the output report (e.g. audit_report.md or audit_report.json).',
    );
  }

  /// List of analyzers to run for this command.
  List<Analyzer> getAnalyzers();

  /// Category names to show in output. Override in subcommands to scope output.
  /// Returns null to show all categories (used by [AuditCommand]).
  List<String>? getActiveCategories() => null;

  @override
  Future<int> run() async {
    final targetPath = p.canonicalize(argResults?['path'] as String? ?? '.');
    final isJson = argResults?['json'] as bool? ?? false;
    final isMarkdown = argResults?['markdown'] as bool? ?? false;
    final outputPath = argResults?['output'] as String?;

    final pubspecFile = File(p.join(targetPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      Logger.error('No pubspec.yaml found at "$targetPath". Is this a Flutter project?');
      return 1;
    }

    if (!isJson && outputPath == null) {
      Logger.info('Scanning Flutter project at "$targetPath"...');
    }

    // 1. Run Scanners
    final pubspecInfo = await PubspecScanner().scan(targetPath);
    final assets = await AssetScanner().scan(targetPath, pubspecInfo);
    final dartFiles = await DartFileScanner().scan(targetPath);
    final directoryScan = await DirectoryScanner().scan(targetPath);

    final project = Project(
      rootPath: targetPath,
      pubspec: pubspecInfo,
      dartFiles: dartFiles,
      assets: assets,
      directoryScan: directoryScan,
    );

    // 2. Run Analyzers
    final issues = <Issue>[];
    for (final analyzer in getAnalyzers()) {
      final results = await analyzer.analyze(project);
      issues.addAll(results);
    }

    // 3. Compute Metrics
    final totalLoc = dartFiles.fold<int>(0, (sum, f) => sum + f.lineCount);
    final metrics = <String, dynamic>{
      'packageCount': pubspecInfo.dependencies.length,
      'devPackageCount': pubspecInfo.devDependencies.length,
      'assetCount': assets.length,
      'dartFileCount': dartFiles.length,
      'totalLoc': totalLoc,
    };

    final report = Report(
      projectName: pubspecInfo.name,
      projectPath: targetPath,
      timestamp: DateTime.now(),
      issues: issues,
      metrics: metrics,
      activeCategories: getActiveCategories(),
    );

    // 4. Render Output
    IOSink? fileSink;
    if (outputPath != null) {
      final outputFile = File(outputPath);
      fileSink = outputFile.openWrite();
    }

    if (isJson) {
      const JsonReporter().report(report, sink: fileSink);
    } else if (isMarkdown) {
      const MarkdownReporter().report(report, sink: fileSink);
      if (outputPath == null) {
        // Default to audit_report.md if requested via markdown flag without explicit output file
        final defaultMdFile = File(p.join(targetPath, 'audit_report.md'));
        await defaultMdFile.writeAsString(
          const MarkdownReporter().generateMarkdown(report),
        );
        Logger.success('Markdown report generated at audit_report.md');
      }
    } else {
      const ConsoleReporter().report(report, sink: fileSink);
    }

    if (fileSink != null) {
      await fileSink.flush();
      await fileSink.close();
      Logger.success('Report successfully written to $outputPath');
    }

    return 0;
  }
}
