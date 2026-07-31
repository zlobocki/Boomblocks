import 'package:boomblocks/systems/music_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('music uses the single soundtrack asset', () {
    expect(MusicService.trackAsset, 'music/soundtrack.mp3');
  });
}
