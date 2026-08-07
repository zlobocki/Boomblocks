import 'dart:math';

import 'package:boomblocks/systems/music_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each mode maps to a distinct looping asset except Mix', () {
    expect(MusicMode.pop.fixedTrack!.asset, 'music/pop.mp3');
    expect(MusicMode.metal.fixedTrack!.asset, 'music/metal.mp3');
    expect(MusicMode.dwarves.fixedTrack!.asset, 'music/dwarves.mp3');
    expect(MusicMode.oldTimes.fixedTrack!.asset, 'music/old_times.mp3');
    expect(MusicMode.mix.fixedTrack, isNull);
  });

  test('mix picker avoids repeating the previous track when possible', () {
    final rng = Random(7);
    var prev = MusicTrack.pop;
    for (var i = 0; i < 40; i++) {
      final next = MusicService.pickMixTrack(prev, rng);
      expect(next, isNot(prev));
      prev = next;
    }
  });
}
