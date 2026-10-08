/// A call's length as `mm:ss`, widening to `hh:mm:ss` past the hour. Shared so
/// the live timer, the banner and the call log all read the same way.
String formatCallDuration(Duration elapsed) {
  final seconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
  final minutes = (seconds ~/ 60).remainder(60).toString().padLeft(2, '0');
  final secs = seconds.remainder(60).toString().padLeft(2, '0');
  final hours = seconds ~/ 3600;
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:$minutes:$secs'
      : '$minutes:$secs';
}
