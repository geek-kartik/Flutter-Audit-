import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/pubspec_info.dart';

/// Scanner responsible for reading and parsing pubspec.yaml files.
class PubspecScanner {
  /// Scans pubspec.yaml at [projectPath] and returns [PubspecInfo].
  Future<PubspecInfo> scan(String projectPath) async {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      return const PubspecInfo(
        name: 'unknown',
        version: '0.0.0',
        dependencies: {},
        devDependencies: {},
        dependencyOverrides: {},
        flutterAssets: [],
        flutterFonts: [],
        flutterPlugins: {},
        rawYaml: '',
        yamlMap: {},
      );
    }

    final rawYaml = await pubspecFile.readAsString();
    final parsed = loadYaml(rawYaml);

    if (parsed is! Map) {
      return PubspecInfo(
        name: 'unknown',
        version: '0.0.0',
        dependencies: const {},
        devDependencies: const {},
        dependencyOverrides: const {},
        flutterAssets: const [],
        flutterFonts: const [],
        flutterPlugins: const {},
        rawYaml: rawYaml,
        yamlMap: const {},
      );
    }

    final name = parsed['name']?.toString() ?? 'unknown';
    final version = parsed['version']?.toString() ?? '0.0.0';

    final dependencies = _extractMap(parsed['dependencies']);
    final devDependencies = _extractMap(parsed['dev_dependencies']);
    final dependencyOverrides = _extractMap(parsed['dependency_overrides']);

    final flutterSection = parsed['flutter'];
    final flutterAssets = <String>[];
    final flutterFonts = <PubspecFont>[];
    Map<String, dynamic> flutterPlugins = {};

    if (flutterSection is Map) {
      // Extract assets
      final assetsRaw = flutterSection['assets'];
      if (assetsRaw is List) {
        for (final item in assetsRaw) {
          if (item is String) {
            flutterAssets.add(item);
          }
        }
      }

      // Extract fonts
      final fontsRaw = flutterSection['fonts'];
      if (fontsRaw is List) {
        for (final fontItem in fontsRaw) {
          if (fontItem is Map) {
            final family = fontItem['family']?.toString();
            final fontFilesRaw = fontItem['fonts'];
            final fontPaths = <String>[];

            if (family != null && fontFilesRaw is List) {
              for (final f in fontFilesRaw) {
                if (f is Map && f['asset'] != null) {
                  fontPaths.add(f['asset'].toString());
                }
              }
              flutterFonts.add(
                PubspecFont(family: family, assetPaths: fontPaths),
              );
            }
          }
        }
      }

      // Extract plugin info
      final pluginRaw = flutterSection['plugin'];
      if (pluginRaw is Map) {
        flutterPlugins = Map<String, dynamic>.from(pluginRaw);
      }
    }

    return PubspecInfo(
      name: name,
      version: version,
      dependencies: dependencies,
      devDependencies: devDependencies,
      dependencyOverrides: dependencyOverrides,
      flutterAssets: flutterAssets,
      flutterFonts: flutterFonts,
      flutterPlugins: flutterPlugins,
      rawYaml: rawYaml,
      yamlMap: Map<dynamic, dynamic>.from(parsed),
    );
  }

  Map<String, String> _extractMap(dynamic yamlNode) {
    final result = <String, String>{};
    if (yamlNode is Map) {
      yamlNode.forEach((key, value) {
        if (key != null) {
          result[key.toString()] = value?.toString() ?? '';
        }
      });
    }
    return result;
  }
}
