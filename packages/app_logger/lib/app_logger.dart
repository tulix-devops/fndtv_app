import 'package:flutter/foundation.dart';
export 'package:logger/logger.dart';
import 'package:app_logger/src/logger_impl.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

final AppLogger logger = AppLoggerImpl();

abstract class AppLogger {
  void v(Object message, {StackTrace? stacktrace}) {
    log(message, LogLevel.verbose);
  }

  void d(Object message, {StackTrace? stacktrace}) {
    log(message, LogLevel.debug);
  }

  void i(Object message, {StackTrace? stacktrace}) {
    log(message, LogLevel.info);
  }

  void w(Object message, {StackTrace? stacktrace}) {
    log(message, LogLevel.warning);
  }

  void e(Object message, {StackTrace? stacktrace}) {
    log(message, LogLevel.error, stacktrace: stacktrace);
  }

  @protected
  void log(Object message, LogLevel level, {StackTrace? stacktrace});
}
