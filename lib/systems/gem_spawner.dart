import 'dart:math';

import '../models/cell.dart';
import '../models/gem.dart';
import 'board_logic.dart';

class GemSpawner {
  GemSpawner([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  static const waveSize = 12;
  static const lootResetAt = 7;

  /// Unlock schedule by round number (1-based):
  /// 1–4 silver; 5+ gold; 10+ emerald; 16+ ruby; 23+ diamond.
  static List<GemType> valuablesForRound(int round) {
    final list = <GemType>[GemType.silver];
    if (round >= 5) list.add(GemType.gold);
    if (round >= 10) list.add(GemType.emerald);
    if (round >= 16) list.add(GemType.ruby);
    if (round >= 23) list.add(GemType.diamond);
    return list;
  }

  int countGemsOnBoard(List<List<BoardCell>> board) {
    var n = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell.hasGem) n++;
      }
    }
    return n;
  }

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

  /// Spawn up to 12 loot items (half worthless fossils), respecting unlock curve.
  int spawnWave(List<List<BoardCell>> board, int round) {
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
    final placeCount = min(candidates.length, waveSize);
    final types = _buildWaveTypes(placeCount, round);
    for (var i = 0; i < placeCount; i++) {
      final p = candidates[i];
      board[p.y][p.x].setGem(types[i], rounds: 99);
    }
    return placeCount;
  }

  List<GemType> _buildWaveTypes(int count, int round) {
    final worthlessCount = count ~/ 2; // at least half
    final valuableCount = count - worthlessCount;
    final valuables = valuablesForRound(round);
    final types = <GemType>[
      for (var i = 0; i < worthlessCount; i++)
        _rng.nextBool() ? GemType.skull : GemType.bones,
      for (var i = 0; i < valuableCount; i++)
        valuables[_rng.nextInt(valuables.length)],
    ];
    types.shuffle(_rng);
    return types;
  }
}
