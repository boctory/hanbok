import 'package:flutter/foundation.dart';

class Logger {
  final String name;

  Logger(this.name);

  void d(String message) {
    _log('DEBUG', message);
  }

  void i(String message) {
    _log('INFO', message);
  }

  void w(String message) {
    _log('WARN', message);
  }

  void e(String message) {
    _log('ERROR', message);
  }

  void _log(String level, String message) {
    if (kDebugMode) {
      print('[$level] ${DateTime.now()} [$name] $message');
    }
  }
}

// 전역 로거 인스턴스
final logger = Logger('HanbokApp'); 