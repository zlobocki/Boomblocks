import 'package:shared_preferences/shared_preferences.dart';

import 'music_service.dart';
import 'sound_service.dart';

/// Persisted music/SFX volume, applied to both audio services.
class AudioSettings {
  static const _musicKey = 'boomblocks_music_volume';
  static const _sfxKey = 'boomblocks_sfx_volume';

  static double music = 0.5;
  static double sfx = 0.75;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      music = prefs.getDouble(_musicKey) ?? 0.5;
      sfx = prefs.getDouble(_sfxKey) ?? 0.75;
    } catch (_) {}
    await MusicService.instance.setVolume(music);
    SoundService.instance.setVolume(sfx);
  }

  static Future<void> setMusic(double value) async {
    music = value.clamp(0.0, 1.0);
    await MusicService.instance.setVolume(music);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_musicKey, music);
    } catch (_) {}
  }

  static Future<void> setSfx(double value) async {
    sfx = value.clamp(0.0, 1.0);
    SoundService.instance.setVolume(sfx);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_sfxKey, sfx);
    } catch (_) {}
  }
}
