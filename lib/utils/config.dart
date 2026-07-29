/// Configurable thresholds for project auditing rules.
class AuditConfig {
  /// Maximum allowed lines for a Widget class before issuing a warning.
  final int maxWidgetLines;

  /// Maximum allowed lines for a function/method before issuing a warning.
  final int maxFunctionLines;

  /// Maximum allowed lines for a class before issuing a warning.
  final int maxClassLines;

  /// Maximum allowed lines for a file before issuing a warning.
  final int maxFileLines;

  /// Maximum allowed widget tree nesting depth before issuing a warning.
  final int maxWidgetNestingDepth;

  /// Maximum allowed constructor parameters before issuing a warning.
  final int maxConstructorParams;

  /// Maximum allowed methods in one class before issuing a warning.
  final int maxMethodsPerClass;

  /// Maximum allowed public members in one class before issuing a warning.
  final int maxPublicMembers;

  /// Size threshold in bytes for large images (default: 500 KB).
  final int largeImageThresholdBytes;

  /// Size threshold in bytes for huge images (default: 1.5 MB).
  final int hugeImageThresholdBytes;

  /// Size threshold in bytes for large SVG files (default: 100 KB).
  final int largeSvgThresholdBytes;

  /// Size threshold in bytes for large JSON / Lottie files (default: 200 KB).
  final int largeJsonThresholdBytes;

  /// Size threshold in bytes for large font files (default: 1 MB).
  final int largeFontThresholdBytes;

  const AuditConfig({
    this.maxWidgetLines = 100,
    this.maxFunctionLines = 40,
    this.maxClassLines = 250,
    this.maxFileLines = 400,
    this.maxWidgetNestingDepth = 6,
    this.maxConstructorParams = 7,
    this.maxMethodsPerClass = 15,
    this.maxPublicMembers = 15,
    this.largeImageThresholdBytes = 500 * 1024,
    this.hugeImageThresholdBytes = 1500 * 1024,
    this.largeSvgThresholdBytes = 100 * 1024,
    this.largeJsonThresholdBytes = 200 * 1024,
    this.largeFontThresholdBytes = 1024 * 1024,
  });
}
