import 'package:flutter_test/flutter_test.dart';
import 'package:talkmos/features/chats/utils/voice_waveform.dart';

/// How many times the sequence changes direction. A real waveform wanders; a
/// ramp or a sawtooth barely turns at all.
int _turningPoints(List<double> bars) {
  var turns = 0;
  for (var i = 1; i < bars.length - 1; i++) {
    final rising = bars[i] > bars[i - 1];
    final thenFalling = bars[i] > bars[i + 1];
    if (rising == thenFalling && bars[i] != bars[i - 1]) turns++;
  }
  return turns;
}

void main() {
  const url = 'https://cdn.talkmos.app/voice/abc123.m4a';

  test('the same clip always draws the same bars', () {
    expect(voiceWaveformBars(url), voiceWaveformBars(url));
  });

  test('different clips do not draw the same bars', () {
    expect(
      voiceWaveformBars(url),
      isNot(voiceWaveformBars('https://cdn.talkmos.app/voice/xyz789.m4a')),
    );
  });

  test('every bar stays inside the track', () {
    for (final bar in voiceWaveformBars(url)) {
      expect(bar, inInclusiveRange(0.0, 1.0));
      // Nothing collapses to an invisible sliver.
      expect(bar, greaterThanOrEqualTo(0.12));
    }
  });

  test('it wanders instead of ramping', () {
    // The generator this replaced multiplied the seed by the bar index, which
    // is linear in the index — it drew a staircase that turned at most once
    // per wrap. Anything that reads as speech turns far more often than that.
    final bars = voiceWaveformBars(url);
    expect(_turningPoints(bars), greaterThan(bars.length ~/ 6));
  });

  test('it is quieter at the ends than in the middle', () {
    final bars = voiceWaveformBars(url);
    final edges = (bars.first + bars.last) / 2;
    final middle = bars[bars.length ~/ 2];
    expect(edges, lessThan(middle));
  });

  test('an odd request length is still honoured', () {
    expect(voiceWaveformBars(url, count: 7).length, 7);
    expect(voiceWaveformBars(url, count: 1).length, 1);
    expect(voiceWaveformBars(url, count: 0), isEmpty);
  });

  test('an empty source still produces a drawable waveform', () {
    final bars = voiceWaveformBars('');
    expect(bars, isNotEmpty);
    expect(bars.every((b) => b > 0), isTrue);
  });
}
