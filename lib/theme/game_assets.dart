import '../models/gem.dart';

/// Paths for gem and consumable artwork.
class GameAssets {
  static const skull = 'assets/images/skull.png';
  static const skull2 = 'assets/images/skull2.png';
  static const bones = 'assets/images/bones.png';
  static const bones2 = 'assets/images/bones2.png';
  static const silver = 'assets/images/silver.png';
  static const gold = 'assets/images/gold.png';
  static const emerald = 'assets/images/emerald.png';
  static const ruby = 'assets/images/ruby.png';
  static const diamond = 'assets/images/diamond.png';
  static const rope = 'assets/images/rope.png';
  static const dynamite = 'assets/images/dynamite.png';
  static const undo = 'assets/images/undo.png';
  static const cashIcon = 'assets/images/cash_icon.png';
  static const welcomeBg = 'assets/images/welcome_bg.jpg';

  static String gem(String gemName) => 'assets/images/$gemName.png';

  /// Asset for a gem at a board cell; fossils mix two icon variants,
  /// chosen stably from the cell position.
  static String gemAt(GemType type, int row, int col) {
    final alt = (row * 7 + col * 13).isOdd;
    return switch (type) {
      GemType.skull => alt ? skull2 : skull,
      GemType.bones => alt ? bones2 : bones,
      _ => gem(type.name),
    };
  }
}
