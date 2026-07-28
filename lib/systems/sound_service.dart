import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Lightweight SFX player for clears.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.7);
      _ready = true;
    } catch (e) {
      debugPrint('SoundService init failed: $e');
    }
  }

  Future<void> playClear({required bool highScore}) async {
    await init();
    try {
      await _player.stop();
      await _player.play(
        AssetSource(highScore ? 'sounds/clear_high.wav' : 'sounds/clear.wav'),
      );
    } catch (e) {
      debugPrint('Sound play failed: $e');
    }
  }
}
