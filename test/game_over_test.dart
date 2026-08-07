import 'package:boomblocks/controllers/game_controller.dart';
import 'package:boomblocks/models/inventory.dart';
import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/persistence/game_storage.dart';
import 'package:boomblocks/systems/board_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestStorage extends GameStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void fillScattered(GameController c) {
    c.board = BoardLogic.emptyBoard();
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var col = 0; col < BoardLogic.size; col++) {
        final hole = col == r || col == (r + 4) % 8;
        if (!hole) c.board[r][col].placeEarth();
      }
    }
  }

  /// Places a monomino into a hole, leaving a square3 that fits nowhere.
  GameController stuckAfterPlacement({int dynamite = 0}) {
    final c = GameController(storage: _TestStorage());
    c.newGame();
    fillScattered(c);
    c.tray = [
      TrayPiece(id: 'a', shape: PieceCatalog.monomino),
      TrayPiece(id: 'b', shape: PieceCatalog.square3),
      null,
    ];
    c.inventory = Inventory(
      rope: ItemMeter(count: 0, threshold: 50),
      dynamite: ItemMeter(count: dynamite, threshold: 65),
      undo: ItemMeter(count: 1, threshold: 80),
    );
    // Checkpoint must match the stuck setup (not the earlier newGame deal).
    c.debugCaptureRoundCheckpoint(dirty: false);
    expect(c.placePiece(0, 0, 0), isTrue);
    return c;
  }

  test('without a round checkpoint, undo charges cannot soft-lock a loss',
      () async {
    final c = GameController(storage: _TestStorage());
    c.newGame();

    c.board = BoardLogic.emptyBoard();
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var col = 0; col < BoardLogic.size; col++) {
        c.board[r][col].placeEarth();
      }
    }
    c.tray = [
      TrayPiece(id: 'stuck', shape: PieceCatalog.monomino),
      null,
      null,
    ];
    c.inventory = Inventory(
      rope: ItemMeter(count: 1, threshold: 50),
      dynamite: ItemMeter(count: 0, threshold: 65),
      undo: ItemMeter(count: 1, threshold: 80),
    );
    c.debugClearRoundCheckpoint();
    expect(c.canUndoPlacement, isFalse);

    final applied = c.applyRopeToPiece(0);
    expect(applied, isTrue);
    expect(c.canUndoPlacement, isFalse);
    expect(c.inventory.dynamite.count, 0);
    expect(
      c.status == GameStatus.disaster || c.status == GameStatus.exploding,
      isTrue,
    );
  });

  test('usable undo forces the stuck choice instead of game over', () {
    final c = stuckAfterPlacement();
    expect(c.canUndoPlacement, isTrue);
    expect(c.status, GameStatus.playing);
    expect(c.stuckChoicePending, isTrue);
    expect(c.tray.whereType<TrayPiece>().length, 1);
  });

  test('stuck prompt: undo restores the round start and clears the prompt', () {
    final c = stuckAfterPlacement();
    expect(c.stuckChoicePending, isTrue);
    c.resolveStuckWithUndo();
    expect(c.stuckChoicePending, isFalse);
    expect(c.status, GameStatus.playing);
    expect(c.inventory.undo.count, 0);
    // Round start restored: hole free, both pieces back, dirty cleared.
    expect(c.board[0][0].filled, isFalse);
    expect(c.tray.whereType<TrayPiece>().length, 2);
    expect(c.canUndoPlacement, isFalse);
    expect(c.piecesPlacedThisRound, 0);
  });

  test('stuck prompt: end game starts the disaster sequence', () {
    final c = stuckAfterPlacement();
    expect(c.stuckChoicePending, isTrue);
    c.resolveStuckEndGame();
    expect(c.stuckChoicePending, isFalse);
    expect(
      c.status == GameStatus.disaster ||
          c.status == GameStatus.exploding ||
          c.status == GameStatus.gameOver,
      isTrue,
    );
  });

  test('no stuck prompt while dynamite remains', () {
    final c = stuckAfterPlacement(dynamite: 1);
    expect(c.stuckChoicePending, isFalse);
    expect(c.status, GameStatus.playing);
  });

  test('undo restores loot counter and consumable meters from round start', () {
    final c = GameController(storage: _TestStorage());
    c.newGame();
    c.board = BoardLogic.emptyBoard();
    c.score = 100;
    c.gemsCollectedTowardReset = 3;
    c.inventory = Inventory(
      rope: ItemMeter(count: 2, progress: 10, threshold: 50),
      dynamite: ItemMeter(count: 1, progress: 20, threshold: 65),
      undo: ItemMeter(count: 2, progress: 5, threshold: 80),
    );
    c.tray = [
      TrayPiece(id: 'a', shape: PieceCatalog.monomino),
      TrayPiece(id: 'b', shape: PieceCatalog.dominoH),
      TrayPiece(id: 'c', shape: PieceCatalog.trominoI),
    ];
    c.debugCaptureRoundCheckpoint(dirty: false);

    expect(c.placePiece(0, 0, 0), isTrue);
    expect(c.canUndoPlacement, isTrue);

    // Spend rope mid-round; undo should restore the pre-spend meter.
    expect(c.applyRopeToPiece(1), isTrue);
    expect(c.inventory.rope.count, 1);

    expect(c.undoLastPlacement(), isTrue);
    expect(c.inventory.rope.count, 2);
    expect(c.inventory.dynamite.count, 1);
    expect(c.inventory.undo.count, 1); // one charge spent
    // Round checkpoint value (loot counter may change mid-round on empty boards).
    expect(c.gemsCollectedTowardReset, 3);
    expect(c.score, 100);
    expect(c.tray.whereType<TrayPiece>().length, 3);
    expect(c.piecesPlacedThisRound, 0);
    expect(c.board[0][0].filled, isFalse);
  });
}
