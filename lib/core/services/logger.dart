enum LogLevel { info, warning, error }

class Logger {
  static void log(LogLevel level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$timestamp][$level] $message');
  }

  static void info(String message) => log(LogLevel.info, message);
  static void warning(String message) => log(LogLevel.warning, message);
  static void error(String message) => log(LogLevel.error, message);
}
