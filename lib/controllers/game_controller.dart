import 'package:flutter/foundation.dart';

import '../models/cell.dart';
import '../models/high_score.dart';
import '../models/inventory.dart';
import '../models/piece.dart';
import '../persistence/game_storage.dart';
import '../systems/board_logic.dart';
import '../systems/gem_spawner.dart';
import '../systems/piece_generator.dart';
import '../systems/sound_service.dart';

enum GameStatus { playing, gameOver }

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

  /// Latest gem point flights for the UI to animate (cleared after consume).
  List<CollectedGem> pendingGemFlights = [];
  int clearEventId = 0;

  static const clearBoardBonusBase = 250;
  static const highScoreClearThreshold = 40;

  Future<void> init({bool forceNew = false}) async {
    await SoundService.instance.init();
    if (!forceNew) {
      final saved = await _storage.loadGame();
      if (saved != null) {
        _fromJson(saved);
        loaded = true;
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
    status = GameStatus.playing;
    maxToast = null;
    lastScoreToast = null;
    pendingGemFlights = [];
    _seedBoard();
    _dealTray();
    loaded = true;
    _persist();
    notifyListeners();
  }

  void _seedBoard() {
    BoardLogic.prefillBoard(board, targetCells: 20 + difficultyLevel * 2);
    _gems.spawnWave(board, difficultyLevel);
  }

  void _dealTray() {
    final dealt = _pieces.dealTrio(difficultyLevel);
    tray = [dealt[0], dealt[1], dealt[2]];
    piecesPlacedThisRound = 0;
    _checkGameOver();
  }

  void clearToasts() {
    maxToast = null;
    lastScoreToast = null;
  }

  void consumeGemFlights() {
    pendingGemFlights = [];
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

  bool canPlaceAt(int trayIndex, int row, int col) {
    final piece = tray[trayIndex];
    if (piece == null) return false;
    return BoardLogic.canPlace(board, piece.shape, row, col);
  }

  bool placePiece(int trayIndex, int row, int col) {
    if (status != GameStatus.playing) return false;
    final piece = tray[trayIndex];
    if (piece == null) return false;
    if (!BoardLogic.canPlace(board, piece.shape, row, col)) return false;

    BoardLogic.placePiece(board, piece.shape, row, col);
    tray[trayIndex] = null;
    piecesPlacedThisRound++;

    final clear = BoardLogic.clearCompletedLines(board);
    _handleClearResult(clear);
    _handleClearBoardBonus();

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

    final result = BoardLogic.clearDynamite(board, row, col);
    _handleClearResult(result);
    _handleClearBoardBonus();
    _checkGameOver();
    _persist();
    notifyListeners();
    return true;
  }

  void _handleClearResult(ClearResult clear) {
    if (clear.linesCleared > 0 || clear.collectedGems.isNotEmpty) {
      final high = clear.score >= highScoreClearThreshold ||
          clear.linesCleared >= 2 ||
          clear.collectedGems.any((g) => g.points >= 25);
      SoundService.instance.playClear(highScore: high);
    }

    if (clear.collectedGems.isNotEmpty) {
      pendingGemFlights = List.of(clear.collectedGems);
      clearEventId++;
    }

    _applyScore(clear.score, clear.linesCleared, clear.gemValueSum);
  }

  void _handleClearBoardBonus() {
    if (!BoardLogic.isEmpty(board)) return;
    final bonus = clearBoardBonusBase * difficultyLevel;
    score += bonus;
    lastScoreToast = 'BOARD CLEAR! +\$$bonus';
    final ropeMax = inventory.rope.addScore(bonus);
    final dynMax = inventory.dynamite.addScore(bonus);
    if (ropeMax || dynMax) maxToast = 'MAX';
    _seedBoard();
  }

  void _applyScore(int gained, int lines, int gemSum) {
    if (gained <= 0) return;
    score += gained;
    lastScoreToast = lines > 1
        ? '+\$$gained  ($lines×\$$gemSum)'
        : '+\$$gained';

    final ropeMax = inventory.rope.addScore(gained);
    final dynMax = inventory.dynamite.addScore(gained);
    if (ropeMax || dynMax) {
      maxToast = 'MAX';
    }
  }

  void _endRound() {
    if (round % 5 == 0) {
      difficultyLevel++;
    }
    round++;
    _gems.onRoundEnd(board, difficultyLevel, round);
    _dealTray();
  }

  /// Game over only when nothing left in the tray can be placed AND the
  /// player has no remaining rope/dynamite to try to fix the situation.
  void _checkGameOver() {
    final remaining = tray.whereType<TrayPiece>().toList();
    if (remaining.isEmpty) return;

    final anyPlaceable =
        remaining.any((p) => BoardLogic.canPlaceAnywhere(board, p));
    if (anyPlaceable) return;

    if (inventory.rope.count > 0 || inventory.dynamite.count > 0) return;

    status = GameStatus.gameOver;
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
    if (status == GameStatus.gameOver) {
      await _storage.clearGame();
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
        'status': status.name,
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
    status = GameStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => GameStatus.playing,
    );
  }
}
