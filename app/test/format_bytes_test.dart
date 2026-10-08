import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/core/utils/format_bytes.dart';

void main() {
  test('renders bytes below a kilobyte exactly', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1), '1 B');
    expect(formatBytes(1023), '1023 B');
  });

  test('never renders a negative size', () {
    expect(formatBytes(-1), '0 B');
  });

  test('steps up through the units', () {
    expect(formatBytes(1024), '1.0 KB');
    expect(formatBytes(1024 * 1024), '1.0 MB');
    expect(formatBytes(1024 * 1024 * 1024), '1.0 GB');
    expect(formatBytes(1024 * 1024 * 1024 * 1024), '1.0 TB');
  });

  test('keeps one decimal below ten and drops it above', () {
    expect(formatBytes(1024 * 3 + 512), '3.5 KB');
    expect(formatBytes(1024 * 1024 * 9 + 512 * 1024), '9.5 MB');
    expect(formatBytes(1024 * 1024 * 241), '241 MB');
  });

  test('rolls over rather than printing 1024 of a unit', () {
    // 1023.99 KB rounds to 1024.0 KB, which should read as 1.0 MB.
    expect(formatBytes(1024 * 1024 - 1), '1.0 MB');
    expect(formatBytes(1024 * 1024 * 1024 - 1), '1.0 GB');
  });

  test('holds the largest unit instead of inventing a new one', () {
    final huge = formatBytes(1024 * 1024 * 1024 * 1024 * 5);
    expect(huge, endsWith('TB'));
  });

  test('a realistic cache size reads cleanly', () {
    expect(formatBytes(87 * 1024 * 1024 + 300 * 1024), '87 MB');
  });
}
