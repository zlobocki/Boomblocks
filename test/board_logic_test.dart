import 'dart:math';

import 'package:boomblocks/models/cell.dart';
import 'package:boomblocks/models/gem.dart';
import 'package:boomblocks/models/inventory.dart';
import 'package:boomblocks/models/piece.dart';
import 'package:boomblocks/systems/board_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardLogic', () {
    test('places and rejects overlap', () {
      final board = BoardLogic.emptyBoard();
      final shape = PieceCatalog.dominoH;
      expect(BoardLogic.canPlace(board, shape, 0, 0), isTrue);
      BoardLogic.placePiece(board, shape, 0, 0);
      expect(board[0][0].filled, isTrue);
      expect(board[0][1].filled, isTrue);
      expect(BoardLogic.canPlace(board, shape, 0, 0), isFalse);
    });

    test('clears full row and scores gems with multiplier', () {
      final board = BoardLogic.emptyBoard();
      for (var c = 0; c < 8; c++) {
        board[0][c].placeEarth();
      }
      board[0][0].setGem(GemType.gold);
      board[0][1].setGem(GemType.coal);
      final result = BoardLogic.clearCompletedLines(board);
      expect(result.rowsCleared, 1);
      expect(result.colsCleared, 0);
      expect(result.gemValueSum, 11);
      expect(result.score, 11);
      expect(board[0].every((c) => !c.filled), isTrue);
    });

    test('multi-line clear multiplies gem value', () {
      final board = BoardLogic.emptyBoard();
      for (var c = 0; c < 8; c++) {
        board[0][c].placeEarth();
        board[1][c].placeEarth();
      }
      board[0][0].setGem(GemType.silver);
      board[1][0].setGem(GemType.silver);
      final result = BoardLogic.clearCompletedLines(board);
      expect(result.linesCleared, 2);
      expect(result.gemValueSum, 10);
      expect(result.score, 20);
    });

    test('dynamite clears 3x3 and scores gems', () {
      final board = BoardLogic.emptyBoard();
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          board[r][c].placeEarth();
        }
      }
      board[1][1].setGem(GemType.ruby);
      final result = BoardLogic.clearDynamite(board, 1, 1);
      expect(result.gemValueSum, 25);
      expect(result.score, 25);
      expect(board[1][1].filled, isFalse);
    });

    test('rope allows checking all rotations for placeability', () {
      final board = BoardLogic.emptyBoard();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (c == 0 && r < 4) continue;
          board[r][c].placeEarth();
        }
      }
      final horizontalI = TrayPiece(
        id: '1',
        shape: PieceCatalog.tetrominoI,
        hasRope: false,
      );
      expect(BoardLogic.canPlaceAnywhere(board, horizontalI), isFalse);

      final withRope = TrayPiece(
        id: '2',
        shape: PieceCatalog.tetrominoI,
        hasRope: true,
      );
      expect(BoardLogic.canPlaceAnywhere(board, withRope), isTrue);
    });

    test('3x3 square and big L orientations have expected sizes', () {
      expect(PieceCatalog.square3.cells.length, 9);
      expect(PieceCatalog.square3.width, 3);
      expect(PieceCatalog.square3.height, 3);
      for (final l in PieceCatalog.bigLAll) {
        expect(l.cells.length, 5);
        expect(l.width, 3);
        expect(l.height, 3);
      }
    });

    test('prefill populates board without completing lines', () {
      final board = BoardLogic.emptyBoard();
      BoardLogic.prefillBoard(board, targetCells: 20, random: Random(1));
      expect(BoardLogic.filledCount(board), greaterThan(10));
      expect(BoardLogic.isEmpty(board), isFalse);
      for (var r = 0; r < 8; r++) {
        expect(board[r].every((c) => c.filled), isFalse);
      }
    });

    test('collected gems include per-gem points with multiplier', () {
      final board = BoardLogic.emptyBoard();
      for (var c = 0; c < 8; c++) {
        board[0][c].placeEarth();
        board[1][c].placeEarth();
      }
      board[0][0].setGem(GemType.gold); // 10
      board[1][3].setGem(GemType.coal); // 1
      final result = BoardLogic.clearCompletedLines(board);
      expect(result.linesCleared, 2);
      expect(result.collectedGems.length, 2);
      expect(result.collectedGems.map((g) => g.points).toSet(), {20, 2});
      expect(result.score, 22);
    });
  });

  group('ItemMeter', () {
    test('grants item on threshold and shows max at cap', () {
      final meter = ItemMeter(count: 2, threshold: 50, maxCount: 2);
      final showMax = meter.addScore(50);
      expect(showMax, isTrue);
      expect(meter.count, 2);
      expect(meter.tier, 1);
    });

    test('increments when under cap', () {
      final meter = ItemMeter(count: 0, threshold: 50, maxCount: 2);
      final showMax = meter.addScore(50);
      expect(showMax, isFalse);
      expect(meter.count, 1);
    });
  });

  group('PieceShape', () {
    test('rotation preserves cell count', () {
      var s = PieceCatalog.tetrominoT;
      for (var i = 0; i < 4; i++) {
        s = s.rotated90();
        expect(s.cells.length, 4);
        expect(s.cells.map((p) => Point(p.x, p.y)).toSet().length, 4);
      }
    });
  });

  group('BoardCell', () {
    test('json roundtrip', () {
      final cell = BoardCell(filled: true)..setGem(GemType.diamond, rounds: 2);
      final copy = BoardCell.fromJson(cell.toJson());
      expect(copy.filled, isTrue);
      expect(copy.gem, GemType.diamond);
      expect(copy.gemRoundsLeft, 2);
    });
  });
}
