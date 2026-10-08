import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/calls/utils/call_duration.dart';

void main() {
  test('reads mm:ss under an hour', () {
    expect(formatCallDuration(Duration.zero), '00:00');
    expect(formatCallDuration(const Duration(seconds: 7)), '00:07');
    expect(formatCallDuration(const Duration(minutes: 9, seconds: 5)), '09:05');
    expect(
      formatCallDuration(const Duration(minutes: 59, seconds: 59)),
      '59:59',
    );
  });

  test('widens to hh:mm:ss past it, rather than counting past 60 minutes', () {
    expect(formatCallDuration(const Duration(hours: 1)), '01:00:00');
    expect(
      formatCallDuration(const Duration(hours: 2, minutes: 5, seconds: 3)),
      '02:05:03',
    );
  });

  test('a clock that went backwards still reads as zero', () {
    expect(formatCallDuration(const Duration(seconds: -30)), '00:00');
  });
}
