// lib/utils/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, printEmojis: true),
    level: Level.debug,
  );

  static void info(String msg)  => _logger.i(msg);
  static void debug(String msg) => _logger.d(msg);
  static void warn(String msg)  => _logger.w(msg);
  static void error(String msg) => _logger.e(msg);
}
