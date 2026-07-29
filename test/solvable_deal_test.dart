import 'package:boomblocks/controllers/game_controller.dart';
import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/persistence/game_storage.dart';
import 'package:boomblocks/systems/puzzle_solver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every new game deals a solvable trio', () async {
    for (var run = 0; run < 15; run++) {
      final c = GameController(storage: GameStorage());
      c.newGame();
      final pieces = c.tray.whereType<TrayPiece>().toList();
      expect(pieces.length, 3);
      final solvable = PuzzleSolver.isSolvable(
        c.board,
        pieces,
        ropeCharges: c.inventory.rope.count,
        dynamiteCharges: c.inventory.dynamite.count,
      );
      expect(solvable, isTrue, reason: 'run $run dealt an unsolvable trio');
    }
  });

  test('deal stays solvable at high difficulty with denser boards', () async {
    for (var run = 0; run < 8; run++) {
      final c = GameController(storage: GameStorage());
      c.newGame();
      // Simulate a late-game board: crank difficulty and reseed.
      c.difficultyLevel = 7;
      c.debugReseedAndDeal();
      final pieces = c.tray.whereType<TrayPiece>().toList();
      expect(pieces.length, 3);
      final solvable = PuzzleSolver.isSolvable(
        c.board,
        pieces,
        ropeCharges: c.inventory.rope.count,
        dynamiteCharges: c.inventory.dynamite.count,
      );
      expect(solvable, isTrue, reason: 'run $run dealt an unsolvable trio');
    }
  });

  test('dealing completes quickly enough for the UI thread', () {
    final c = GameController(storage: GameStorage());
    c.newGame();
    c.difficultyLevel = 8;
    final sw = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      c.debugReseedAndDeal();
    }
    sw.stop();
    // 5 reseeds + solver-validated deals; generous bound for CI machines.
    expect(sw.elapsedMilliseconds, lessThan(5000));
  });
}
