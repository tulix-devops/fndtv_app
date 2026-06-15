import 'package:app_logger/app_logger.dart';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';

final _defaultLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 6,
    lineLength: 50,
    colors: io.stdout.supportsAnsiEscapes,
    printEmojis: true,
  
  ),
);

class AppLoggerImpl extends AppLogger {
  final Logger logger;

  AppLoggerImpl({Logger? logger}) : logger = logger ?? _defaultLogger;

  @override
  void log(Object message, LogLevel level, {StackTrace? stacktrace}) {
    if (kReleaseMode) return;

    switch (level) {
      case LogLevel.verbose:
        logger.t(message, stackTrace: stacktrace);
        break;
      case LogLevel.debug:
        logger.d(message, stackTrace: stacktrace);
        break;
      case LogLevel.info:
        logger.i(message, stackTrace: stacktrace);
        break;
      case LogLevel.warning:
        logger.w(message, stackTrace: stacktrace);
        break;
      case LogLevel.error:
        logger.e(message, stackTrace: stacktrace);
        break;
    }
  }
}
