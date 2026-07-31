import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Background music: loops a single track from `assets/music/soundtrack.mp3`.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  static const String trackAsset = 'music/soundtrack.mp3';

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;
  double _volume = 0.5;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      // Music holds normal media focus; SFX are configured not to take it.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gain,
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.music,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(trackAsset), volume: _volume);
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!_started) return;
    try {
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      }
    } catch (_) {}
  }
}
