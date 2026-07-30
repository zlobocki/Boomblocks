import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Background music: strictly alternates between a random long track and a
/// random short track. Tracks are discovered from `assets/music/` at runtime;
/// filenames containing "long"/"short" decide the category (anything else
/// counts as long). If the folder is empty, music stays silently disabled.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();

  final List<String> _long = [];
  final List<String> _short = [];
  bool _started = false;
  bool _nextIsLong = false;
  double _volume = 0.5;

  /// Picks the next track and the category flag for the pick after it.
  /// Falls back to the other pool when one category has no tracks.
  @visibleForTesting
  static (String?, bool) pickNext(
    List<String> long,
    List<String> short,
    bool nextIsLong,
    Random rng,
  ) {
    var pool = nextIsLong ? long : short;
    if (pool.isEmpty) pool = nextIsLong ? short : long;
    if (pool.isEmpty) return (null, !nextIsLong);
    return (pool[rng.nextInt(pool.length)], !nextIsLong);
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (!asset.startsWith('assets/music/')) continue;
        final lower = asset.toLowerCase();
        if (!lower.endsWith('.mp3') &&
            !lower.endsWith('.ogg') &&
            !lower.endsWith('.wav')) {
          continue;
        }
        if (lower.contains('short')) {
          _short.add(asset);
        } else {
          _long.add(asset);
        }
      }
      if (_long.isEmpty && _short.isEmpty) return;

      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(_volume);
      _player.onPlayerComplete.listen((_) => _playNext());
      _nextIsLong = _rng.nextBool();
      await _playNext();
    } catch (e) {
      debugPrint('MusicService start failed: $e');
    }
  }

  Future<void> _playNext() async {
    final (track, flip) = pickNext(_long, _short, _nextIsLong, _rng);
    _nextIsLong = flip;
    if (track == null) return;
    try {
      await _player.play(
        AssetSource(track.replaceFirst('assets/', '')),
        volume: _volume,
      );
    } catch (e) {
      debugPrint('Music play failed: $e');
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
