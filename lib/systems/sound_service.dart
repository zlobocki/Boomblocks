import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum ClearSoundKind { zero, single, multi }

/// Lightweight SFX player.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.75);
      _ready = true;
    } catch (e) {
      debugPrint('SoundService init failed: $e');
    }
  }

  Future<void> _play(String asset) async {
    await init();
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Sound play failed: $e');
    }
  }

  Future<void> playClear(ClearSoundKind kind) => _play(switch (kind) {
        ClearSoundKind.zero => 'sounds/clear_zero.mp3',
        ClearSoundKind.single => 'sounds/clear_row.mp3',
        ClearSoundKind.multi => 'sounds/clear_multi.mp3',
      });

  Future<void> playGameOver({required bool top10}) =>
      _play(top10 ? 'sounds/game_over_top10.mp3' : 'sounds/game_over.mp3');
}
