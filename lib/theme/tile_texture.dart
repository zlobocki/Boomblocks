import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Decoded block-tile texture shared by the board and piece painters.
/// Painters fall back to gradient blocks until this finishes loading.
class TileTexture {
  static ui.Image? image;

  static Future<void> load() async {
    if (image != null) return;
    try {
      final data = await rootBundle.load('assets/images/tile1.png');
      image = await decodeImageFromList(data.buffer.asUint8List());
    } catch (_) {
      // Missing/corrupt asset → keep painted fallback.
    }
  }
}
