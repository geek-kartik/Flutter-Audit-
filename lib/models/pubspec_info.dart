import 'package:meta/meta.dart';

/// Information extracted from pubspec.yaml.
@immutable
class PubspecInfo {
  /// Name of the package/project.
  final String name;

  /// Version of the project.
  final String version;

  /// Production dependencies declared in pubspec.yaml.
  final Map<String, String> dependencies;

  /// Development dependencies declared in pubspec.yaml.
  final Map<String, String> devDependencies;

  /// Dependency overrides declared in pubspec.yaml.
  final Map<String, String> dependencyOverrides;

  /// Assets listed under the flutter: assets: section.
  final List<String> flutterAssets;

  /// Fonts listed under the flutter: fonts: section.
  final List<PubspecFont> flutterFonts;

  /// Plugins declared in flutter: plugin: or dependencies.
  final Map<String, dynamic> flutterPlugins;

  /// Raw YAML content string for line number lookup or duplicate key checking.
  final String rawYaml;

  /// Raw decoded YAML map.
  final Map<dynamic, dynamic> yamlMap;

  const PubspecInfo({
    required this.name,
    required this.version,
    required this.dependencies,
    required this.devDependencies,
    required this.dependencyOverrides,
    required this.flutterAssets,
    required this.flutterFonts,
    required this.flutterPlugins,
    required this.rawYaml,
    required this.yamlMap,
  });
}

/// Information about a font family declared in pubspec.yaml.
@immutable
class PubspecFont {
  final String family;
  final List<String> assetPaths;

  const PubspecFont({
    required this.family,
    required this.assetPaths,
  });
}
