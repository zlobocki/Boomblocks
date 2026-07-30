import 'package:boomblocks/controllers/game_controller.dart';
import 'package:boomblocks/models/inventory.dart';
import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/persistence/game_storage.dart';
import 'package:boomblocks/systems/board_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage that never touches prefs disk beyond the mock.
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

  /// Places a monomino into one of the scattered holes, leaving a square3
  /// that fits nowhere. No lines clear (every row/col keeps ≥1 hole).
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
    expect(c.placePiece(0, 0, 0), isTrue);
    return c;
  }

  test('unused undo charge does not prevent game over when nothing fits',
      () async {
    final c = GameController(storage: _TestStorage());
    c.newGame();

    // Fill entire board so nothing can be placed.
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
    // No placement snapshot → undo is unusable.
    expect(c.canUndoPlacement, isFalse);

    // applyRopeToPiece re-runs the game-over check after consuming the rope.
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

  test('stuck prompt: undo restores the last move and clears the prompt', () {
    final c = stuckAfterPlacement();
    expect(c.stuckChoicePending, isTrue);
    c.resolveStuckWithUndo();
    expect(c.stuckChoicePending, isFalse);
    expect(c.status, GameStatus.playing);
    expect(c.inventory.undo.count, 0);
    // Board restored: the hole is free again and the monomino is back.
    expect(c.board[0][0].filled, isFalse);
    expect(c.tray.whereType<TrayPiece>().length, 2);
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
    // Dynamite can still open space → no forced choice.
    expect(c.stuckChoicePending, isFalse);
    expect(c.status, GameStatus.playing);
  });
}
