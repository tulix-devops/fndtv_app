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
    if (kReleaseMode) {
      // Release builds used to drop every log line, which made field logcats
      // blind: the 2026-07-31 X88pro10 capture contained the app's raw print()
      // calls but not one diagnostic (decoder profile, mpv tuning, stall
      // watchdog…) — all of it muted here. The STB fleet runs release builds
      // and QA debugging depends on those lines, so info+ now goes to logcat
      // as plain single lines (PrettyPrinter's box-drawing stays debug-only —
      // it is unreadable in logcat exports). debugPrint throttles output, so
      // a burst cannot flood the kernel ring buffer.
      switch (level) {
        case LogLevel.verbose:
        case LogLevel.debug:
          return;
        case LogLevel.info:
        case LogLevel.warning:
        case LogLevel.error:
          debugPrint(
            stacktrace == null ? '$message' : '$message\n$stacktrace',
          );
          return;
      }
    }

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
