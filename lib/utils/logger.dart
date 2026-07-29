import 'dart:io';

/// Logging utility supporting ANSI colored console output.
class Logger {
  static bool enableColors = true;

  /// Print success message with green checkmark.
  static void success(String message, {IOSink? sink}) {
    final symbol = colorize('✓', '32');
    _print('$symbol $message', sink: sink);
  }

  /// Print warning message with yellow warning symbol.
  static void warning(String message, {IOSink? sink}) {
    final symbol = colorize('⚠', '33');
    _print('$symbol $message', sink: sink);
  }

  /// Print error message with red cross symbol.
  static void error(String message, {IOSink? sink}) {
    final symbol = colorize('✗', '31');
    _print('$symbol $message', sink: sink);
  }

  /// Print info message with blue info symbol.
  static void info(String message, {IOSink? sink}) {
    final symbol = colorize('ℹ', '36');
    _print('$symbol $message', sink: sink);
  }

  /// Print section header.
  static void header(String title, {IOSink? sink}) {
    _print('', sink: sink);
    _print(colorize(title, '1;34'), sink: sink); // Bold Blue
    _print(colorize('─' * 40, '90'), sink: sink); // Gray rule
  }

  /// Colorize string with ANSI code.
  static String colorize(String text, String code) {
    if (!enableColors || !stdout.hasTerminal) return text;
    return '\x1B[${code}m$text\x1B[0m';
  }

  /// Bold text styling.
  static String bold(String text) {
    return colorize(text, '1');
  }

  static void _print(String message, {IOSink? sink}) {
    if (sink != null) {
      sink.writeln(message);
    } else {
      // ignore: avoid_print
      print(message);
    }
  }
}
