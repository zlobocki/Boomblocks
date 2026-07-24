import 'dart:math';

import '../models/piece.dart';

class PieceGenerator {
  PieceGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  List<TrayPiece> dealTrio(int difficultyLevel) {
    final bag = _bagFor(difficultyLevel);
    return List.generate(3, (i) {
      final shape = bag[_rng.nextInt(bag.length)];
      // Random initial rotation for variety (0-3)
      var s = shape;
      final turns = _rng.nextInt(4);
      for (var t = 0; t < turns; t++) {
        s = s.rotated90();
      }
      return TrayPiece(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        shape: s,
      );
    });
  }

  List<PieceShape> _bagFor(int level) {
    if (level <= 2) return PieceCatalog.easy;
    if (level <= 5) {
      return [...PieceCatalog.easy, ...PieceCatalog.medium, ...PieceCatalog.medium];
    }
    if (level <= 8) {
      return [...PieceCatalog.medium, ...PieceCatalog.hard];
    }
    return PieceCatalog.hard;
  }
}
