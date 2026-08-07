import 'package:boomblocks/controllers/game_controller.dart';
import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/persistence/game_storage.dart';
import 'package:boomblocks/systems/piece_generator.dart';
import 'package:boomblocks/systems/puzzle_solver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every new game deals a trio solvable without consumables', () async {
    for (var run = 0; run < 15; run++) {
      final c = GameController(storage: GameStorage());
      c.newGame();
      final pieces = c.tray.whereType<TrayPiece>().toList();
      expect(pieces.length, 3);
      final solvable = PuzzleSolver.isSolvable(
        c.board,
        pieces,
        ropeCharges: 0,
        dynamiteCharges: 0,
      );
      expect(
        solvable,
        isTrue,
        reason: 'run $run dealt an unsolvable trio without items',
      );
      // Fresh deal must not immediately game-over.
      expect(c.status, GameStatus.playing);
      expect(c.stuckChoicePending, isFalse);
    }
  });

  test('deal stays solvable at high difficulty with denser boards', () async {
    for (var run = 0; run < 10; run++) {
      final c = GameController(storage: GameStorage());
      c.newGame();
      c.difficultyLevel = 9;
      c.debugReseedAndDeal();
      final pieces = c.tray.whereType<TrayPiece>().toList();
      expect(pieces.length, 3);
      final solvable = PuzzleSolver.isSolvable(
        c.board,
        pieces,
        ropeCharges: 0,
        dynamiteCharges: 0,
      );
      expect(
        solvable,
        isTrue,
        reason: 'run $run dealt an unsolvable trio without items',
      );
      expect(c.status, GameStatus.playing);
    }
  });

  test('ease-break rounds use easier bags', () {
    final ease = PieceGenerator.bagFor(9, DealBias.easeBreak);
    final hard = PieceGenerator.bagFor(9, DealBias.normal);
    expect(ease.any((s) => s.id == 'mono'), isTrue);
    expect(hard.any((s) => s.id == 'mono'), isFalse);
  });

  test('isEaseBreakRound hits every 5th round', () {
    final c = GameController(storage: GameStorage());
    c.newGame();
    expect(c.isEaseBreakRound, isFalse);
    c.round = 5;
    expect(c.isEaseBreakRound, isTrue);
    c.round = 10;
    expect(c.isEaseBreakRound, isTrue);
    c.round = 11;
    expect(c.isEaseBreakRound, isFalse);
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
    expect(sw.elapsedMilliseconds, lessThan(8000));
  });
}
