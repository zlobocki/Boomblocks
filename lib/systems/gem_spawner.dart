import 'dart:math';

import '../models/cell.dart';
import '../models/gem.dart';
import 'board_logic.dart';

class GemSpawner {
  GemSpawner([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  /// Age gems by one round and remove expired ones.
  void ageGems(List<List<BoardCell>> board) {
    for (final row in board) {
      for (final cell in row) {
        if (!cell.hasGem) continue;
        cell.gemRoundsLeft--;
        if (cell.gemRoundsLeft <= 0) {
          cell.gem = null;
          cell.gemRoundsLeft = 0;
        }
      }
    }
  }

  /// Spawn a fresh wave of gems on occupied earth cells without gems.
  void spawnWave(List<List<BoardCell>> board, int difficultyLevel) {
    final candidates = <Point<int>>[];
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var c = 0; c < BoardLogic.size; c++) {
        final cell = board[r][c];
        if (cell.filled && !cell.hasGem) {
          candidates.add(Point(c, r));
        }
      }
    }
    if (candidates.isEmpty) return;

    candidates.shuffle(_rng);
    final count = _spawnCount(difficultyLevel, candidates.length);
    for (var i = 0; i < count; i++) {
      final p = candidates[i];
      board[p.y][p.x].setGem(_pickGem(difficultyLevel), rounds: 2);
    }
  }

  /// Called at end of each round: age existing, then top-up / refresh.
  void onRoundEnd(List<List<BoardCell>> board, int difficultyLevel, int round) {
    ageGems(board);
    // Every 2 rounds, also force-refresh remaining gems from prior wave.
    if (round % 2 == 0) {
      for (final row in board) {
        for (final cell in row) {
          if (cell.hasGem) {
            cell.gem = null;
            cell.gemRoundsLeft = 0;
          }
        }
      }
      spawnWave(board, difficultyLevel);
    } else {
      // Odd rounds: top-up a few new gems so the board stays interesting.
      spawnWave(board, difficultyLevel);
    }
  }

  int _spawnCount(int level, int available) {
    // Early: more gems; later: fewer but richer.
    final base = level <= 3 ? 6 : (level <= 7 ? 4 : 3);
    return min(available, base + _rng.nextInt(3));
  }

  GemType _pickGem(int level) {
    final roll = _rng.nextDouble();
    if (level <= 2) {
      if (roll < 0.55) return GemType.coal;
      if (roll < 0.85) return GemType.silver;
      if (roll < 0.95) return GemType.gold;
      return GemType.emerald;
    }
    if (level <= 5) {
      if (roll < 0.30) return GemType.coal;
      if (roll < 0.55) return GemType.silver;
      if (roll < 0.75) return GemType.gold;
      if (roll < 0.90) return GemType.emerald;
      if (roll < 0.97) return GemType.ruby;
      return GemType.diamond;
    }
    if (roll < 0.15) return GemType.coal;
    if (roll < 0.35) return GemType.silver;
    if (roll < 0.55) return GemType.gold;
    if (roll < 0.75) return GemType.emerald;
    if (roll < 0.90) return GemType.ruby;
    return GemType.diamond;
  }
}
