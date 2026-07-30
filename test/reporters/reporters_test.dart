import 'dart:convert';
import 'package:flutter_audit/models/issue.dart';
import 'package:flutter_audit/models/report.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:flutter_audit/reporters/json_reporter.dart';
import 'package:flutter_audit/reporters/markdown_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('Reporters and Health Score', () {
    test('calculates health score accurately based on score penalties', () {
      final issues = [
        const Issue(
          id: 'unused_dependency',
          title: 'Unused dio',
          description: 'Unused dep',
          severity: Severity.warning,
          category: 'Dependencies',
          scorePenalty: 2,
        ),
        const Issue(
          id: 'unused_asset',
          title: 'Unused asset.png',
          description: 'Unused asset',
          severity: Severity.warning,
          category: 'Assets',
          scorePenalty: 1,
        ),
        const Issue(
          id: 'unused_dart_file',
          title: 'Unused screen.dart',
          description: 'Unused dart file',
          severity: Severity.warning,
          category: 'Directory',
          scorePenalty: 3,
        ),
      ];

      final report = Report(
        projectName: 'demo_app',
        projectPath: '/root',
        timestamp: DateTime(2026, 1, 1),
        issues: issues,
        metrics: {'packageCount': 10, 'assetCount': 5, 'dartFileCount': 3},
      );

      // 100 - (2 + 1 + 3) = 94
      expect(report.healthScore, equals(94));
    });

    test('JsonReporter produces valid structured JSON', () {
      final report = Report(
        projectName: 'demo_app',
        projectPath: '/root',
        timestamp: DateTime(2026, 1, 1),
        issues: [
          const Issue(
            id: 'unused_dependency',
            title: 'Unused dio',
            description: 'Unused dep',
            severity: Severity.warning,
            category: 'Dependencies',
            scorePenalty: 2,
          ),
        ],
        metrics: {'packageCount': 5},
      );

      final jsonMap = report.toJson();
      final encoded = jsonEncode(jsonMap);
      final decoded = jsonDecode(encoded);

      expect(decoded['projectName'], equals('demo_app'));
      expect(decoded['healthScore'], equals(98));
      expect(decoded['issues'], isA<List>());
      expect(decoded['issues'].length, equals(1));
    });

    test('MarkdownReporter generates valid markdown report', () {
      final report = Report(
        projectName: 'demo_app',
        projectPath: '/root',
        timestamp: DateTime(2026, 1, 1),
        issues: [],
        metrics: {'packageCount': 5},
      );

      const reporter = MarkdownReporter();
      final markdown = reporter.generateMarkdown(report);

      expect(markdown, contains('# Flutter Project Audit Report'));
      expect(markdown, contains('Project Health Score: 100 / 100'));
    });
  });
}
