import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cell.dart';
import '../models/high_score.dart';
import '../models/inventory.dart';
import '../models/piece.dart';
import '../persistence/game_storage.dart';
import '../systems/board_logic.dart';
import '../systems/gem_spawner.dart';
import '../systems/piece_generator.dart';
import '../systems/puzzle_solver.dart';
import '../systems/sound_service.dart';
import '../theme/tile_texture.dart';

enum GameStatus { playing, disaster, exploding, gameOver }

class PlacementSnapshot {
  PlacementSnapshot({
    required this.board,
    required this.tray,
    required this.score,
    required this.gemsCollectedTowardReset,
    required this.piecesPlacedThisRound,
    required this.inventory,
  });

  final List<List<BoardCell>> board;
  final List<TrayPiece?> tray;
  final int score;
  final int gemsCollectedTowardReset;
  final int piecesPlacedThisRound;
  final Inventory inventory;
}

class GameController extends ChangeNotifier {
  GameController({GameStorage? storage}) : _storage = storage ?? GameStorage();

  final GameStorage _storage;
  final PieceGenerator _pieces = PieceGenerator();
  final GemSpawner _gems = GemSpawner();

  List<List<BoardCell>> board = BoardLogic.emptyBoard();
  List<TrayPiece?> tray = [null, null, null];
  late Inventory inventory;
  int score = 0;
  int round = 1;
  int difficultyLevel = 1;
  int piecesPlacedThisRound = 0;
  GameStatus status = GameStatus.playing;
  String? maxToast;
  String? lastScoreToast;
  bool loaded = false;

  /// True when the player is stuck (no fits, no dynamite) but still holds a
  /// usable undo: the UI must ask "undo last move or end game?".
  bool stuckChoicePending = false;

  final Random _rng = Random();

  /// Block tile in use (1-based); rotated on every loot reset.
  int tileIndex = 1;

  /// Recently used tiles, newest last — a new tile must not repeat any of
  /// these. Capped at [tileHistoryWindow].
  List<int> tileHistory = [];
  static const tileHistoryWindow = 10;

  int gemsCollectedTowardReset = 0;
  static const lootResetAt = GemSpawner.lootResetAt;

  List<CollectedGem> pendingGemFlights = [];
  int clearEventId = 0;

  /// Cells currently playing shatter animation.
  List<Point<int>> explodingCells = [];
  int explosionEventId = 0;

  PlacementSnapshot? _undoSnapshot;
  bool get canUndoPlacement =>
      status == GameStatus.playing &&
      _undoSnapshot != null &&
      inventory.undo.count > 0;

  static const clearBoardBonusBase = 250;

  Future<void> init({bool forceNew = false}) async {
    await SoundService.instance.init();
    if (!forceNew) {
      final saved = await _storage.loadGame();
      if (saved != null) {
        _fromJson(saved);
        loaded = true;
        // A restored game may already be stuck (undo snapshots don't
        // survive restarts) — re-evaluate instead of soft-locking.
        _checkGameOver();
        notifyListeners();
        return;
      }
    }
    newGame();
  }

  void newGame() {
    board = BoardLogic.emptyBoard();
    inventory = Inventory();
    score = 0;
    round = 1;
    difficultyLevel = 1;
    piecesPlacedThisRound = 0;
    gemsCollectedTowardReset = 0;
    status = GameStatus.playing;
    maxToast = null;
    lastScoreToast = null;
    pendingGemFlights = [];
    explodingCells = [];
    _undoSnapshot = null;
    stuckChoicePending = false;
    tileHistory = [];
    _seedBoard();
    _dealTray();
    loaded = true;
    _persist();
    notifyListeners();
  }

  void _seedBoard() {
    BoardLogic.prefillBoard(board, targetCells: 26 + difficultyLevel * 2);
    _gems.spawnWave(board, round);
    gemsCollectedTowardReset = 0;
    _rotateTile();
  }

  /// Picks a random tile that hasn't been used in the last
  /// [tileHistoryWindow] loot resets. All blocks share the single tile.
  void _rotateTile() {
    final candidates = [
      for (var t = 1; t <= TileTexture.count; t++)
        if (!tileHistory.contains(t)) t,
    ];
    final pool = candidates.isNotEmpty
        ? candidates
        : [
            for (var t = 1; t <= TileTexture.count; t++)
              if (t != tileIndex) t,
          ];
    tileIndex = pool[_rng.nextInt(pool.length)];
    tileHistory.add(tileIndex);
    while (tileHistory.length > tileHistoryWindow) {
      tileHistory.removeAt(0);
    }
    TileTexture.currentIndex = tileIndex;
  }

  void _dealTray() {
    tray = _dealSolvableTrio();
    piecesPlacedThisRound = 0;
    _undoSnapshot = null;
    _checkGameOver();
  }

  /// Deals a trio guaranteed (best effort) to have at least one sequential
  /// solution from the current board, possibly requiring rope/dynamite the
  /// player currently holds. Higher difficulty prefers deals with the fewest
  /// solutions — ideally a single order-dependent sequence.
  List<TrayPiece?> _dealSolvableTrio() {
    const attempts = 10;
    const countCap = 24;
    // (trio, rawSolutionCount) — raw counts ignore consumables; 0 means the
    // deal is solvable only by spending rope/dynamite.
    final candidates = <(List<TrayPiece>, int)>[];

    List<TrayPiece>? fallback;
    for (var a = 0; a < attempts; a++) {
      final trio = _pieces.dealTrio(difficultyLevel);
      fallback ??= trio;
      final raw = PuzzleSolver.countSolutions(
        board,
        trio,
        limit: countCap,
        nodeBudget: 60000,
      );
      if (raw > 0) {
        candidates.add((trio, raw));
        continue;
      }
      final withItems = PuzzleSolver.isSolvable(
        board,
        trio,
        ropeCharges: inventory.rope.count,
        dynamiteCharges: inventory.dynamite.count,
        nodeBudget: 60000,
      );
      if (withItems) candidates.add((trio, 0));
    }

    if (candidates.isEmpty) {
      // No solvable deal found within budget; keep the first roll and let the
      // normal game-over logic take it from here.
      return [fallback![0], fallback[1], fallback[2]];
    }

    // Sort by raw count ascending, treating consumable-dependent deals (0) as
    // the hardest tier.
    candidates.sort((a, b) {
      int rank(int raw) => raw == 0 ? -1 : raw;
      return rank(a.$2).compareTo(rank(b.$2));
    });

    List<TrayPiece> chosen;
    if (difficultyLevel >= 6) {
      // Hardest available: fewest solutions (single-solution when possible).
      chosen = candidates
          .firstWhere((c) => c.$2 == 1, orElse: () => candidates.first)
          .$1;
    } else if (difficultyLevel >= 3) {
      chosen = candidates[candidates.length ~/ 2].$1;
    } else {
      // Early rounds: most forgiving deal.
      chosen = candidates.last.$1;
    }
    return [chosen[0], chosen[1], chosen[2]];
  }

  /// Test hook: reseed the board at current difficulty and deal a new tray.
  @visibleForTesting
  void debugReseedAndDeal() {
    board = BoardLogic.emptyBoard();
    _seedBoard();
    _dealTray();
  }

  /// Test hook: force a tile rotation (normally driven by loot resets).
  @visibleForTesting
  void debugRotateTile() => _rotateTile();

  void clearToasts() {
    maxToast = null;
    lastScoreToast = null;
  }

  void consumeGemFlights() {
    pendingGemFlights = [];
  }

  void clearExplosion() {
    if (explodingCells.isEmpty) return;
    // Keep markers through the disaster blow-up so blocks don't reappear.
    if (status == GameStatus.disaster || status == GameStatus.exploding) {
      return;
    }
    explodingCells = [];
    notifyListeners();
  }

  PlacementSnapshot _captureSnapshot() {
    return PlacementSnapshot(
      board: BoardLogic.cloneBoard(board),
      tray: tray.map((p) => p?.copy()).toList(),
      score: score,
      gemsCollectedTowardReset: gemsCollectedTowardReset,
      piecesPlacedThisRound: piecesPlacedThisRound,
      inventory: Inventory(
        rope: inventory.rope.copy(),
        dynamite: inventory.dynamite.copy(),
        undo: inventory.undo.copy(),
      ),
    );
  }

  bool undoLastPlacement() {
    if (!canUndoPlacement) return false;
    final snap = _undoSnapshot!;
    if (!inventory.undo.tryConsume()) return false;

    board = BoardLogic.cloneBoard(snap.board);
    tray = snap.tray.map((p) => p?.copy()).toList();
    while (tray.length < 3) {
      tray.add(null);
    }
    score = snap.score;
    gemsCollectedTowardReset = snap.gemsCollectedTowardReset;
    piecesPlacedThisRound = snap.piecesPlacedThisRound;
    // Restore meters except undo count (already consumed current).
    final undoLeft = inventory.undo.count;
    final undoProgress = inventory.undo.progress;
    final undoThreshold = inventory.undo.threshold;
    final undoTier = inventory.undo.tier;
    inventory = Inventory(
      rope: snap.inventory.rope.copy(),
      dynamite: snap.inventory.dynamite.copy(),
      undo: ItemMeter(
        count: undoLeft,
        progress: undoProgress,
        threshold: undoThreshold,
        tier: undoTier,
      ),
    );
    _undoSnapshot = null;
    stuckChoicePending = false;
    lastScoreToast = 'Undone';
    pendingGemFlights = [];
    explodingCells = [];
    _checkGameOver();
    _persist();
    notifyListeners();
    return true;
  }

  bool applyRopeToPiece(int trayIndex) {
    if (status != GameStatus.playing) return false;
    final piece = tray[trayIndex];
    if (piece == null || piece.hasRope) return false;
    if (!inventory.rope.tryConsume()) return false;
    piece.hasRope = true;
    _checkGameOver();
    _persist();
    notifyListeners();
    return true;
  }

  void rotatePiece(int trayIndex) {
    final piece = tray[trayIndex];
    if (piece == null || !piece.hasRope) return;
    piece.rotate();
    _checkGameOver();
    notifyListeners();
  }

  bool placePiece(int trayIndex, int row, int col) {
    if (status != GameStatus.playing) return false;
    final piece = tray[trayIndex];
    if (piece == null) return false;
    if (!BoardLogic.canPlace(board, piece.shape, row, col)) return false;

    _undoSnapshot = _captureSnapshot();

    BoardLogic.placePiece(board, piece.shape, row, col);
    tray[trayIndex] = null;
    piecesPlacedThisRound++;

    final clear = BoardLogic.clearCompletedLines(board);
    _handleClearResult(clear);
    _handleClearBoardBonus();
    _maybeRespawnLootIfEmpty();

    if (piecesPlacedThisRound >= 3 || tray.every((p) => p == null)) {
      _endRound();
    } else {
      _checkGameOver();
    }

    _persist();
    notifyListeners();
    return true;
  }

  bool useDynamite(int row, int col) {
    if (status != GameStatus.playing) return false;
    if (!inventory.dynamite.tryConsume()) return false;
    // Dynamite is not undoable as a placement.
    _undoSnapshot = null;

    final result = BoardLogic.clearDynamite(board, row, col);
    _handleClearResult(result);
    _handleClearBoardBonus();
    _maybeRespawnLootIfEmpty();
    _checkGameOver();
    _persist();
    notifyListeners();
    return true;
  }

  void _handleClearResult(ClearResult clear) {
    final didClear =
        clear.linesCleared > 0 || clear.clearedCells.isNotEmpty;
    if (didClear) {
      if (clear.score <= 0) {
        SoundService.instance.playClear(ClearSoundKind.zero);
      } else if (clear.linesCleared >= 2) {
        SoundService.instance.playClear(ClearSoundKind.multi);
      } else {
        SoundService.instance.playClear(ClearSoundKind.single);
      }
    }

    if (clear.clearedCells.isNotEmpty) {
      explodingCells = List.of(clear.clearedCells);
      explosionEventId++;
    }

    final paying = clear.collectedGems.where((g) => g.points > 0).toList();
    if (paying.isNotEmpty) {
      pendingGemFlights = paying;
      clearEventId++;
    }

    if (clear.collectedGems.isNotEmpty) {
      gemsCollectedTowardReset += clear.collectedGems.length;
      if (gemsCollectedTowardReset >= lootResetAt) {
        gemsCollectedTowardReset %= lootResetAt;
        _refreshLootWave();
      }
    }

    _applyScore(clear.score, clear.linesCleared, clear.gemValueSum);
  }

  void _maybeRespawnLootIfEmpty() {
    if (_gems.countGemsOnBoard(board) == 0 && !BoardLogic.isEmpty(board)) {
      gemsCollectedTowardReset = 0;
      _refreshLootWave();
    }
  }

  void _refreshLootWave() {
    _gems.clearAllGems(board);
    _gems.spawnWave(board, round);
    _rotateTile();
    lastScoreToast = 'New loot!';
  }

  void _handleClearBoardBonus() {
    if (!BoardLogic.isEmpty(board)) return;
    final bonus = clearBoardBonusBase * difficultyLevel;
    score += bonus;
    lastScoreToast = 'BOARD CLEAR! +\$$bonus';
    _feedMeters(bonus);
    _seedBoard();
  }

  void _applyScore(int gained, int lines, int gemSum) {
    if (gained <= 0) return;
    score += gained;
    lastScoreToast = lines > 1
        ? '+\$$gained  ($lines×\$$gemSum)'
        : '+\$$gained';
    _feedMeters(gained);
  }

  void _feedMeters(int points) {
    final ropeMax = inventory.rope.addScore(points);
    final dynMax = inventory.dynamite.addScore(points);
    final undoMax = inventory.undo.addScore(points);
    if (ropeMax || dynMax || undoMax) maxToast = 'MAX';
  }

  void _endRound() {
    if (round % 5 == 0) {
      difficultyLevel++;
    }
    round++;
    _undoSnapshot = null;
    _dealTray();
  }

  void _checkGameOver() {
    if (status != GameStatus.playing) return;
    final remaining = tray.whereType<TrayPiece>().toList();
    if (remaining.isEmpty) return;

    final considerRotations = inventory.rope.count > 0;
    final anyPlaceable = remaining.any(
      (p) => BoardLogic.canPlaceAnywhere(
        board,
        p,
        allRotations: considerRotations || p.hasRope,
      ),
    );
    if (anyPlaceable) return;

    // Nothing fits, even considering rope rotations when rope is available
    // or a piece already has rope.
    if (inventory.dynamite.count > 0) return; // player can still blast open

    if (canUndoPlacement) {
      // Undo is the only way out — force the choice instead of soft-locking.
      stuckChoicePending = true;
      notifyListeners();
      return;
    }

    _startDisasterSequence();
  }

  /// Player chose "Undo last move" in the stuck prompt.
  void resolveStuckWithUndo() {
    if (!stuckChoicePending) return;
    stuckChoicePending = false;
    undoLastPlacement();
  }

  /// Player chose "End game" in the stuck prompt.
  void resolveStuckEndGame() {
    if (!stuckChoicePending) return;
    stuckChoicePending = false;
    _startDisasterSequence();
  }

  Future<void> _startDisasterSequence() async {
    status = GameStatus.disaster;
    _undoSnapshot = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (status != GameStatus.disaster) return;

    final cells = <Point<int>>[];
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var c = 0; c < BoardLogic.size; c++) {
        if (board[r][c].filled) cells.add(Point(c, r));
      }
    }
    explodingCells = cells;
    explosionEventId++;
    status = GameStatus.exploding;
    notifyListeners();

    final qualifies = await _storage.qualifiesForTop10(score);
    SoundService.instance.playGameOver(top10: qualifies);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (status != GameStatus.exploding) return;

    for (final row in board) {
      for (final cell in row) {
        cell.clear();
      }
    }
    explodingCells = [];
    status = GameStatus.gameOver;
    await _storage.clearGame();
    notifyListeners();
  }

  Future<bool> qualifiesForScoreboard() => _storage.qualifiesForTop10(score);

  Future<List<HighScoreEntry>> submitHighScore(String name) {
    final entry = HighScoreEntry(
      name: name.trim().isEmpty ? 'Player' : name.trim(),
      score: score,
      dateIso: DateTime.now().toIso8601String(),
    );
    return _storage.submitScore(entry);
  }

  Future<List<HighScoreEntry>> loadScores() => _storage.loadScores();

  Future<void> abandonAndClear() async {
    await _storage.clearGame();
  }

  Future<void> _persist() async {
    if (status == GameStatus.gameOver ||
        status == GameStatus.disaster ||
        status == GameStatus.exploding) {
      return;
    }
    await _storage.saveGame(toJson());
  }

  Map<String, dynamic> toJson() => {
        'board':
            board.map((row) => row.map((c) => c.toJson()).toList()).toList(),
        'tray': tray.map((p) => p?.toJson()).toList(),
        'inventory': inventory.toJson(),
        'score': score,
        'round': round,
        'difficultyLevel': difficultyLevel,
        'piecesPlacedThisRound': piecesPlacedThisRound,
        'gemsCollectedTowardReset': gemsCollectedTowardReset,
        'tileIndex': tileIndex,
        'tileHistory': tileHistory,
        'status': GameStatus.playing.name,
      };

  void _fromJson(Map<String, dynamic> json) {
    board = (json['board'] as List)
        .map((row) => (row as List)
            .map((c) => BoardCell.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList())
        .toList();
    tray = (json['tray'] as List).map((p) {
      if (p == null) return null;
      return TrayPiece.fromJson(Map<String, dynamic>.from(p as Map));
    }).toList();
    while (tray.length < 3) {
      tray.add(null);
    }
    inventory = Inventory.fromJson(
        Map<String, dynamic>.from(json['inventory'] as Map));
    score = json['score'] as int? ?? 0;
    round = json['round'] as int? ?? 1;
    difficultyLevel = json['difficultyLevel'] as int? ?? 1;
    piecesPlacedThisRound = json['piecesPlacedThisRound'] as int? ?? 0;
    gemsCollectedTowardReset = json['gemsCollectedTowardReset'] as int? ?? 0;
    tileIndex = (json['tileIndex'] as int? ?? 1).clamp(1, TileTexture.count);
    tileHistory = [
      for (final t in (json['tileHistory'] as List? ?? const []))
        (t as num).toInt(),
    ];
    TileTexture.currentIndex = tileIndex;
    status = GameStatus.playing;
    _undoSnapshot = null;
  }
}
