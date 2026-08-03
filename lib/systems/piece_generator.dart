import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/piece.dart';

/// How aggressively the deal draws from easier bags.
enum DealBias {
  /// Normal difficulty curve for [difficultyLevel].
  normal,

  /// Periodic breather: mostly easy/medium even at high difficulty.
  easeBreak,

  /// Emergency fallback while searching for a solvable deal.
  rescue,
}

class PieceGenerator {
  PieceGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  List<TrayPiece> dealTrio(
    int difficultyLevel, {
    DealBias bias = DealBias.normal,
  }) {
    final bag = bagFor(difficultyLevel, bias);
    return List.generate(3, (i) {
      final shape = bag[_rng.nextInt(bag.length)];
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

  /// Exposed for tests — which catalog mix a bias/level uses.
  @visibleForTesting
  static List<PieceShape> bagFor(int level, DealBias bias) {
    switch (bias) {
      case DealBias.easeBreak:
        return [
          ...PieceCatalog.easy,
          ...PieceCatalog.easy,
          ...PieceCatalog.medium,
        ];
      case DealBias.rescue:
        return [
          ...PieceCatalog.easy,
          ...PieceCatalog.easy,
          ...PieceCatalog.easy,
          PieceCatalog.monomino,
          PieceCatalog.dominoH,
          PieceCatalog.trominoI,
        ];
      case DealBias.normal:
        if (level <= 2) return PieceCatalog.easy;
        if (level <= 5) {
          return [
            ...PieceCatalog.easy,
            ...PieceCatalog.medium,
            ...PieceCatalog.medium,
          ];
        }
        if (level <= 8) {
          return [...PieceCatalog.medium, ...PieceCatalog.hard];
        }
        return PieceCatalog.hard;
    }
  }
}
