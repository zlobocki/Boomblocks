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
      board[0][0].setGem(GemType.gold); // 10
      board[0][1].setGem(GemType.coal); // 1
      final result = BoardLogic.clearCompletedLines(board);
      expect(result.rowsCleared, 1);
      expect(result.colsCleared, 0);
      expect(result.gemValueSum, 11);
      expect(result.score, 11); // 1 line × 11
      expect(board[0].every((c) => !c.filled), isTrue);
    });

    test('multi-line clear multiplies gem value', () {
      final board = BoardLogic.emptyBoard();
      for (var c = 0; c < 8; c++) {
        board[0][c].placeEarth();
        board[1][c].placeEarth();
      }
      board[0][0].setGem(GemType.silver); // 5
      board[1][0].setGem(GemType.silver); // 5
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
      board[1][1].setGem(GemType.ruby); // 25
      final result = BoardLogic.clearDynamite(board, 1, 1);
      expect(result.gemValueSum, 25);
      expect(result.score, 25); // no lines → mult 1
      expect(board[1][1].filled, isFalse);
    });

    test('rope allows checking all rotations for placeability', () {
      final board = BoardLogic.emptyBoard();
      // Fill almost everything leaving a vertical 4-gap in col 0
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
      final cell = BoardCell(filled: true)
        ..setGem(GemType.diamond, rounds: 2);
      final copy = BoardCell.fromJson(cell.toJson());
      expect(copy.filled, isTrue);
      expect(copy.gem, GemType.diamond);
      expect(copy.gemRoundsLeft, 2);
    });
  });
}
