import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Named background tracks shipped in `assets/music/`.
enum MusicTrack {
  pop('Pop', 'music/pop.mp3'),
  metal('Metal', 'music/metal.mp3'),
  dwarves('Dwarves', 'music/dwarves.mp3'),
  oldTimes('Old Times', 'music/old_times.mp3');

  const MusicTrack(this.label, this.asset);
  final String label;
  final String asset;

  static MusicTrack? tryParse(String? raw) {
    if (raw == null) return null;
    for (final t in MusicTrack.values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// Player choice: a fixed track, or Mix (shuffle tracks end-to-end).
enum MusicMode {
  pop(MusicTrack.pop),
  metal(MusicTrack.metal),
  dwarves(MusicTrack.dwarves),
  oldTimes(MusicTrack.oldTimes),
  mix(null);

  const MusicMode(this.fixedTrack);
  final MusicTrack? fixedTrack;

  String get label => switch (this) {
        MusicMode.pop => MusicTrack.pop.label,
        MusicMode.metal => MusicTrack.metal.label,
        MusicMode.dwarves => MusicTrack.dwarves.label,
        MusicMode.oldTimes => MusicTrack.oldTimes.label,
        MusicMode.mix => 'Mix',
      };

  static MusicMode parse(String? raw) {
    for (final m in MusicMode.values) {
      if (m.name == raw) return m;
    }
    return MusicMode.mix;
  }
}

/// Background music with selectable tracks and a Mix shuffle mode.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();
  bool _started = false;
  double _volume = 0.5;
  MusicMode _mode = MusicMode.mix;
  MusicTrack? _currentTrack;

  MusicMode get mode => _mode;
  MusicTrack? get currentTrack => _currentTrack;

  @visibleForTesting
  static MusicTrack pickMixTrack(MusicTrack? previous, Random rng) {
    final tracks = MusicTrack.values;
    if (tracks.length == 1) return tracks.first;
    MusicTrack next;
    do {
      next = tracks[rng.nextInt(tracks.length)];
    } while (previous != null && next == previous);
    return next;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
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
      await _player.setVolume(_volume);
      _player.onPlayerComplete.listen((_) => _onTrackComplete());
      await _playForMode(restart: true);
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> setMode(MusicMode mode) async {
    if (_mode == mode && _started) return;
    _mode = mode;
    if (!_started) return;
    await _playForMode(restart: true);
  }

  Future<void> _onTrackComplete() async {
    if (!_started) return;
    if (_mode == MusicMode.mix) {
      await _playForMode(restart: true);
    } else {
      // Fixed tracks use loop mode; completion is a belt-and-suspenders restart.
      await _playForMode(restart: false);
    }
  }

  Future<void> _playForMode({required bool restart}) async {
    final track = _mode == MusicMode.mix
        ? pickMixTrack(restart ? _currentTrack : null, _rng)
        : _mode.fixedTrack!;
    _currentTrack = track;
    try {
      await _player.setReleaseMode(
        _mode == MusicMode.mix ? ReleaseMode.stop : ReleaseMode.loop,
      );
      await _player.play(AssetSource(track.asset), volume: _volume);
    } catch (e) {
      debugPrint('Music play failed ($track): $e');
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
