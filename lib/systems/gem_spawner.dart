import 'dart:math';

import '../models/cell.dart';
import '../models/gem.dart';
import 'board_logic.dart';

class GemSpawner {
  GemSpawner([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  static const minWaveSize = 10;

  int countGemsOnBoard(List<List<BoardCell>> board) {
    var n = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell.hasGem) n++;
      }
    }
    return n;
  }

  /// Remove every collectible currently on the board.
  void clearAllGems(List<List<BoardCell>> board) {
    for (final row in board) {
      for (final cell in row) {
        if (cell.hasGem) {
          cell.gem = null;
          cell.gemRoundsLeft = 0;
        }
      }
    }
  }

  /// Spawn a wave: at least [minWaveSize] items when possible, half coal.
  /// Returns how many gems were placed.
  int spawnWave(List<List<BoardCell>> board, int difficultyLevel) {
    final candidates = <Point<int>>[];
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var c = 0; c < BoardLogic.size; c++) {
        final cell = board[r][c];
        if (cell.filled && !cell.hasGem) {
          candidates.add(Point(c, r));
        }
      }
    }
    if (candidates.isEmpty) return 0;

    candidates.shuffle(_rng);
    final placeCount = min(candidates.length, max(minWaveSize, 10));

    final types = _buildWaveTypes(placeCount, difficultyLevel);
    for (var i = 0; i < placeCount; i++) {
      final p = candidates[i];
      board[p.y][p.x].setGem(types[i], rounds: 99);
    }
    return placeCount;
  }

  /// Half coal (rounded down), remainder valuable gems by difficulty.
  List<GemType> _buildWaveTypes(int count, int difficultyLevel) {
    final coalCount = count ~/ 2;
    final valuableCount = count - coalCount;
    final types = <GemType>[
      ...List.filled(coalCount, GemType.coal),
      for (var i = 0; i < valuableCount; i++) _pickValuable(difficultyLevel),
    ];
    types.shuffle(_rng);
    return types;
  }

  GemType _pickValuable(int level) {
    final roll = _rng.nextDouble();
    if (level <= 2) {
      if (roll < 0.55) return GemType.silver;
      if (roll < 0.85) return GemType.gold;
      return GemType.emerald;
    }
    if (level <= 5) {
      if (roll < 0.30) return GemType.silver;
      if (roll < 0.55) return GemType.gold;
      if (roll < 0.80) return GemType.emerald;
      if (roll < 0.95) return GemType.ruby;
      return GemType.diamond;
    }
    if (roll < 0.20) return GemType.silver;
    if (roll < 0.40) return GemType.gold;
    if (roll < 0.65) return GemType.emerald;
    if (roll < 0.85) return GemType.ruby;
    return GemType.diamond;
  }
}
