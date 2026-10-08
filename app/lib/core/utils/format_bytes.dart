String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';

  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }

  // Rounding can push a value up to 1024 of its unit (e.g. 1023.6 KB), which
  // should read as the next unit up rather than "1024 KB".
  if (value >= 1023.95 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }

  final rendered = value < 10
      ? value.toStringAsFixed(1)
      : value.round().toString();
  return '$rendered ${units[unit]}';
}
