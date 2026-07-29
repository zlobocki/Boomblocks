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
      rope: ItemMeter(count: 0, threshold: 50),
      dynamite: ItemMeter(count: 0, threshold: 65),
      undo: ItemMeter(count: 1, threshold: 80),
    );
    // No placement snapshot → undo is unusable.
    expect(c.canUndoPlacement, isFalse);

    // Trigger check via a no-op rotate path: use public place rejection then
    // force check by applying a rope attempt (fails) — instead call through
    // useDynamite failure. Easiest: placePiece won't run. Use undo which fails,
    // then manually invoke by dealing — clear snapshot already null.
    // Public entry: rotatePiece is no-op without rope. applyRope fails.
    // Call placePiece with invalid — returns false without check.
    // So use a tiny filled gap reopen then place? Simpler: use reflection-free
    // approach via ending a fake "successful" path:
    c.inventory.rope.count = 0;
    // Force check by temporarily making one empty cell, placing, refilling.
    // Actually the cleanest public trigger is undoLastPlacement no-op.
    // We'll poke status through a successful dynamite with 0 count (false).
    //
    // Direct: fill leaves no place; call _checkGameOver via placing nothing.
    // Expose by dealing tray after filling:
    // _dealTray is private; _endRound is private.
    // placePiece on full board returns false without checkGameOver.
    //
    // Workaround: clear one cell, place monomino (creates snapshot), undo it
    // (consumes undo), refill — not testing unused undo.
    //
    // Instead: leave undo unusable and trigger via applyRopeToPiece after
    // giving rope then consuming? applyRope calls _checkGameOver.
    c.inventory.rope.count = 1;
    final applied = c.applyRopeToPiece(0);
    expect(applied, isTrue);
    // Now piece has rope; still can't place on full board; rope spent.
    // dynamite 0, undo unusable → disaster.
    expect(c.canUndoPlacement, isFalse);
    expect(c.inventory.dynamite.count, 0);
    // applyRope already called _checkGameOver.
    expect(
      c.status == GameStatus.disaster || c.status == GameStatus.exploding,
      isTrue,
    );
  });

  test('usable undo keeps game alive when pieces do not fit', () async {
    final c = GameController(storage: _TestStorage());
    c.newGame();

    // Start from a clean board: one empty cell, then place to create undo snapshot.
    c.board = BoardLogic.emptyBoard();
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var col = 0; col < BoardLogic.size; col++) {
        if (r == 0 && col == 0) continue;
        c.board[r][col].placeEarth();
      }
    }
    c.tray = [
      TrayPiece(id: 'a', shape: PieceCatalog.monomino),
      TrayPiece(id: 'b', shape: PieceCatalog.square3),
      null,
    ];
    c.inventory = Inventory(
      rope: ItemMeter(count: 0, threshold: 50),
      dynamite: ItemMeter(count: 0, threshold: 65),
      undo: ItemMeter(count: 1, threshold: 80),
    );
    expect(c.placePiece(0, 0, 0), isTrue);
    expect(c.canUndoPlacement, isTrue);
    // After placing monomino, board is full; square3 remains and cannot fit.
    // Undo is usable → should stay playing.
    expect(c.status, GameStatus.playing);
    expect(c.tray.whereType<TrayPiece>().length, greaterThan(0));
  });
}
