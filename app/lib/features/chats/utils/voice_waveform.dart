import 'dart:math' as math;

/// Bar heights for a voice note's waveform, as fractions of the full height.
///
/// The audio is never decoded — these stand in for a real amplitude envelope.
/// They only have to be stable for a given [seedSource] and to *look* like
/// speech, which means varied but not spiky: neighbouring samples of a voice
/// are correlated, so pure noise reads as static rather than a recording.
List<double> voiceWaveformBars(String seedSource, {int count = 34}) {
  if (count <= 0) return const [];

  // xorshift32. The previous generator multiplied the seed by the bar index,
  // which is linear in the index — its low bits stepped by a constant and
  // wrapped, drawing a sawtooth ramp instead of a waveform.
  var state = (seedSource.hashCode ^ 0x9e3779b9) & 0xFFFFFFFF;
  if (state == 0) state = 0x1a2b3c4d;

  double next() {
    state ^= (state << 13) & 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    return state / 0xFFFFFFFF;
  }

  final raw = List<double>.generate(count, (_) => next());

  // One smoothing pass over each sample and its neighbours, which is what
  // turns noise into something that undulates like a voice.
  final smoothed = List<double>.generate(count, (i) {
    final before = raw[(i - 1).clamp(0, count - 1)];
    final after = raw[(i + 1).clamp(0, count - 1)];
    return (before + raw[i] * 2 + after) / 4;
  });

  // Taper the ends so the bar row reads as a clip with a start and a stop
  // rather than a block of noise cut off at both edges.
  return List<double>.generate(count, (i) {
    final edge = math.min(i, count - 1 - i) / (count * 0.18);
    final envelope = 0.55 + 0.45 * edge.clamp(0.0, 1.0);
    return (0.18 + smoothed[i] * 0.82 * envelope).clamp(0.12, 1.0);
  });
}
