import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_audit/commands/architecture_command.dart';
import 'package:flutter_audit/commands/assets_command.dart';
import 'package:flutter_audit/commands/audit_command.dart';
import 'package:flutter_audit/commands/dependencies_command.dart';
import 'package:flutter_audit/commands/performance_command.dart';
import 'package:flutter_audit/utils/logger.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>(
    'flutter_audit',
    'A modular, extensible, offline Flutter project auditing CLI tool.',
  )
    ..addCommand(AuditCommand())
    ..addCommand(AssetsCommand())
    ..addCommand(DependenciesCommand())
    ..addCommand(ArchitectureCommand())
    ..addCommand(PerformanceCommand());

  // Support running global flags or empty command by defaulting to `audit`
  List<String> effectiveArgs = args;
  if (args.isEmpty || (args.isNotEmpty && args.first.startsWith('-'))) {
    effectiveArgs = ['audit', ...args];
  }

  try {
    final result = await runner.run(effectiveArgs);
    exitCode = result ?? 0;
  } on UsageException catch (e) {
    Logger.error(e.message);
    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print(e.usage);
    exitCode = 64;
  } catch (e, stackTrace) {
    Logger.error('An unexpected error occurred during execution: $e');
    // ignore: avoid_print
    print(stackTrace);
    exitCode = 1;
  }
}
