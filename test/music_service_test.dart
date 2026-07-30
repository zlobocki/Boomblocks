import 'dart:math';

import 'package:boomblocks/systems/music_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('music strictly alternates long and short categories', () {
    final long = ['assets/music/song_long_a.mp3', 'assets/music/song_long_b.mp3'];
    final short = ['assets/music/jingle_short_a.mp3'];
    final rng = Random(7);

    var nextIsLong = true;
    final picks = <String>[];
    for (var i = 0; i < 20; i++) {
      final (track, flip) = MusicService.pickNext(long, short, nextIsLong, rng);
      picks.add(track!);
      nextIsLong = flip;
    }
    for (var i = 0; i < picks.length; i++) {
      final expectLong = i.isEven;
      expect(
        picks[i].contains('long'),
        expectLong,
        reason: 'pick #$i should be ${expectLong ? 'long' : 'short'}',
      );
    }
  });

  test('falls back to the other pool when a category is empty', () {
    final rng = Random(1);
    final (track, _) =
        MusicService.pickNext(['assets/music/only_long.mp3'], [], false, rng);
    expect(track, 'assets/music/only_long.mp3');
    final (none, _) = MusicService.pickNext([], [], true, rng);
    expect(none, isNull);
  });
}
