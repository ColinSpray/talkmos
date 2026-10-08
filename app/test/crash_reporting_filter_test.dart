import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/services/crash_reporting.dart';

void main() {
  test('a failed image load is not a crash', () {
    final details = FlutterErrorDetails(
      exception: Exception('HttpException: Invalid statusCode: 404'),
      library: 'image resource service',
    );
    expect(CrashReporting.isWorthReporting(details), isFalse);
  });

  test('a widget error still is', () {
    final details = FlutterErrorDetails(
      exception: StateError('bad state'),
      library: 'widgets library',
    );
    expect(CrashReporting.isWorthReporting(details), isTrue);
  });
}
