import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/systems/board_logic.dart';
import 'package:boomblocks/systems/puzzle_solver.dart';
import 'package:flutter_test/flutter_test.dart';

TrayPiece _p(String id, PieceShape shape) => TrayPiece(id: id, shape: shape);

void main() {
  group('PuzzleSolver', () {
    test('empty board trio is solvable with many solutions', () {
      final board = BoardLogic.emptyBoard();
      final pieces = [
        _p('a', PieceCatalog.monomino),
        _p('b', PieceCatalog.dominoH),
        _p('c', PieceCatalog.trominoI),
      ];
      expect(PuzzleSolver.isSolvable(board, pieces), isTrue);
      expect(
        PuzzleSolver.countSolutions(board, pieces, limit: 10),
        10,
      );
    });

    test('late-game pentomino trio is solvable on an empty board', () {
      final board = BoardLogic.emptyBoard();
      final pieces = [
        _p('t5', PieceCatalog.pentominoT),
        _p('plus', PieceCatalog.plus),
        _p('s', PieceCatalog.tetrominoS),
      ];
      expect(PuzzleSolver.isSolvable(board, pieces), isTrue);
    });

    test('full board is unsolvable without consumables', () {
      final board = BoardLogic.emptyBoard();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          board[r][c].placeEarth();
        }
      }
      final pieces = [_p('a', PieceCatalog.monomino)];
      expect(PuzzleSolver.isSolvable(board, pieces), isFalse);
      // Dynamite blows open a 3x3 → solvable.
      expect(
        PuzzleSolver.isSolvable(board, pieces, dynamiteCharges: 1),
        isTrue,
      );
    });

    test('rope rotation unlocks otherwise impossible placement', () {
      final board = BoardLogic.emptyBoard();
      // Only a 4-tall vertical slot at column 0 is free.
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (c == 0 && r < 4) continue;
          board[r][c].placeEarth();
        }
      }
      final pieces = [_p('a', PieceCatalog.tetrominoI)]; // horizontal I
      expect(PuzzleSolver.isSolvable(board, pieces), isFalse);
      expect(PuzzleSolver.isSolvable(board, pieces, ropeCharges: 1), isTrue);
    });

    test('sequential single solution: domino clears a row, square then fits',
        () {
      final board = BoardLogic.emptyBoard();
      // Fill everything, then carve out:
      // - row 0 gap at cols 0-1 (domino completes and clears row 0)
      // - a 2×3 window at rows 1-2 × cols 0-2 (square3 needs the cleared row
      //   0 above it to fit)
      // - isolated single holes on the diagonal so no other row/column is
      //   ever pre-completed or completed mid-sequence, and no other piece
      //   placement exists there (dominoes/squares can't fit single cells).
      final holes = <(int, int)>{
        (0, 0), (0, 1),
        (1, 0), (1, 1), (1, 2),
        (2, 0), (2, 1), (2, 2),
        (3, 3), (4, 4), (5, 5), (6, 6), (7, 7),
      };
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (!holes.contains((r, c))) board[r][c].placeEarth();
        }
      }
      final pieces = [
        _p('domino', PieceCatalog.dominoH),
        _p('square', PieceCatalog.square3),
      ];
      // Square alone cannot fit before the clear.
      expect(
        PuzzleSolver.isSolvable(board, [_p('s', PieceCatalog.square3)]),
        isFalse,
      );
      // Domino first → row 0 clears → square fits: exactly one sequence.
      expect(PuzzleSolver.isSolvable(board, pieces), isTrue);
      expect(PuzzleSolver.countSolutions(board, pieces, limit: 50), 1);
    });

    test('identical shapes are not double counted', () {
      final board = BoardLogic.emptyBoard();
      // Two usable domino slots plus isolated single holes (unusable by
      // dominoes) that keep every row/column from pre-completing.
      final holes = <(int, int)>{
        (0, 0), (0, 1), (0, 6),
        (2, 0), (2, 1), (2, 5),
        (1, 4), (3, 6), (4, 3), (5, 5), (6, 7), (7, 2),
      };
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (!holes.contains((r, c))) board[r][c].placeEarth();
        }
      }
      final pieces = [
        _p('d1', PieceCatalog.dominoH),
        _p('d2', PieceCatalog.dominoH),
      ];
      // Two slots, two identical dominoes → 2 ordered sequences (slot A
      // first or slot B first), not 4 (piece identity swap is deduplicated).
      expect(PuzzleSolver.countSolutions(board, pieces, limit: 10), 2);
    });
  });
}
