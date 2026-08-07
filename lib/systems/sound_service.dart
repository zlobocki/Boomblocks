import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum ClearSoundKind { zero, single, multi }

/// Lightweight SFX player.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();
  bool _ready = false;
  double _volume = 0.75;

  Future<void> init() async {
    if (_ready) return;
    try {
      // SFX must never request audio focus, or Android pauses the music
      // player every time an effect fires.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      // Short SFX: low-latency mode (SoundPool on Android) cuts the audible
      // delay between an action and its sound.
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(_volume);
      _ready = true;
    } catch (e) {
      debugPrint('SoundService init failed: $e');
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume).catchError((_) {});
  }

  Future<void> _play(String asset) async {
    await init();
    try {
      await _player.stop();
      await _player.play(AssetSource(asset), volume: _volume);
    } catch (e) {
      debugPrint('Sound play failed: $e');
    }
  }

  Future<void> playClear(ClearSoundKind kind) => _play(switch (kind) {
        ClearSoundKind.zero => 'sounds/clear_zero.mp3',
        ClearSoundKind.single => 'sounds/clear_row.mp3',
        ClearSoundKind.multi => 'sounds/clear_multi.mp3',
      });

  /// Block landed without clearing anything.
  Future<void> playThud() =>
      _play('sounds/thud${1 + _rng.nextInt(2)}.mp3');

  Future<void> playGameOver({required bool top10}) =>
      _play(top10 ? 'sounds/game_over_top10.mp3' : 'sounds/game_over.mp3');
}
