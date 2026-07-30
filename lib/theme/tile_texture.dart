import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Decoded block-tile textures shared by the board and piece painters.
/// One tile is active at a time; the game rotates it on every loot reset.
/// Painters fall back to gradient blocks until textures finish loading.
class TileTexture {
  static const count = 21;

  static final Map<int, ui.Image> _images = {};

  /// 1-based index of the tile currently used for all blocks.
  static int currentIndex = 1;

  static ui.Image? get image =>
      _images[currentIndex] ?? (_images.isEmpty ? null : _images.values.first);

  static Future<void> load() async {
    if (_images.isNotEmpty) return;
    for (var i = 1; i <= count; i++) {
      try {
        final data = await rootBundle.load('assets/images/tiles/tile$i.png');
        _images[i] = await decodeImageFromList(data.buffer.asUint8List());
      } catch (_) {
        // Missing/corrupt tile → skipped; getter falls back to any loaded.
      }
    }
  }
}
