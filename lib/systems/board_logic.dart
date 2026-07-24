import 'dart:math';

import '../models/cell.dart';
import '../models/gem.dart';
import '../models/piece.dart';

class ClearResult {
  ClearResult({
    required this.rowsCleared,
    required this.colsCleared,
    required this.gemValueSum,
    required this.clearedCells,
  });

  final int rowsCleared;
  final int colsCleared;
  final int gemValueSum;
  final List<Point<int>> clearedCells;

  int get linesCleared => rowsCleared + colsCleared;

  int get score {
    if (gemValueSum <= 0) return 0;
    final mult = linesCleared <= 0 ? 1 : linesCleared;
    return mult * gemValueSum;
  }
}

class BoardLogic {
  static const size = 8;

  static List<List<BoardCell>> emptyBoard() => List.generate(
        size,
        (_) => List.generate(size, (_) => BoardCell()),
      );

  static List<List<BoardCell>> cloneBoard(List<List<BoardCell>> board) =>
      board.map((row) => row.map((c) => c.copy()).toList()).toList();

  static bool canPlace(
    List<List<BoardCell>> board,
    PieceShape shape,
    int originRow,
    int originCol,
  ) {
    for (final p in shape.cells) {
      final r = originRow + p.y;
      final c = originCol + p.x;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (board[r][c].filled) return false;
    }
    return true;
  }

  static bool canPlaceAnywhere(
    List<List<BoardCell>> board,
    TrayPiece piece,
  ) {
    final orientations = <PieceShape>[piece.shape];
    if (piece.hasRope) {
      var s = piece.shape;
      for (var i = 0; i < 3; i++) {
        s = s.rotated90();
        orientations.add(s);
      }
    }
    for (final shape in orientations) {
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (canPlace(board, shape, r, c)) return true;
        }
      }
    }
    return false;
  }

  /// True if every remaining tray piece has at least one legal placement.
  static bool allPiecesPlaceable(
    List<List<BoardCell>> board,
    List<TrayPiece?> tray,
  ) {
    for (final piece in tray) {
      if (piece == null) continue;
      if (!canPlaceAnywhere(board, piece)) return false;
    }
    return true;
  }

  static void placePiece(
    List<List<BoardCell>> board,
    PieceShape shape,
    int originRow,
    int originCol,
  ) {
    for (final p in shape.cells) {
      final r = originRow + p.y;
      final c = originCol + p.x;
      board[r][c].placeEarth();
    }
  }

  static ClearResult clearCompletedLines(List<List<BoardCell>> board) {
    final fullRows = <int>[];
    final fullCols = <int>[];

    for (var r = 0; r < size; r++) {
      if (board[r].every((c) => c.filled)) fullRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (!board[r][c].filled) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    final cleared = <Point<int>>{};
    var gemSum = 0;

    void collect(int r, int c) {
      final cell = board[r][c];
      if (!cell.filled) return;
      if (cell.hasGem) gemSum += cell.gem!.value;
      cleared.add(Point(c, r));
    }

    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        collect(r, c);
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        collect(r, c);
      }
    }

    for (final p in cleared) {
      board[p.y][p.x].clear();
    }

    return ClearResult(
      rowsCleared: fullRows.length,
      colsCleared: fullCols.length,
      gemValueSum: gemSum,
      clearedCells: cleared.toList(),
    );
  }

  /// Clears a 3x3 centered on (row, col). Returns gem sum cleared.
  static ClearResult clearDynamite(
    List<List<BoardCell>> board,
    int row,
    int col,
  ) {
    var gemSum = 0;
    final cleared = <Point<int>>[];
    for (var r = row - 1; r <= row + 1; r++) {
      for (var c = col - 1; c <= col + 1; c++) {
        if (r < 0 || r >= size || c < 0 || c >= size) continue;
        final cell = board[r][c];
        if (!cell.filled) continue;
        if (cell.hasGem) gemSum += cell.gem!.value;
        cell.clear();
        cleared.add(Point(c, r));
      }
    }
    // Dynamite itself doesn't fill lines; after blast, check if any
    // remaining full lines exist (unlikely but harmless).
    final followUp = clearCompletedLines(board);
    return ClearResult(
      rowsCleared: followUp.rowsCleared,
      colsCleared: followUp.colsCleared,
      gemValueSum: gemSum + followUp.gemValueSum,
      clearedCells: [...cleared, ...followUp.clearedCells],
    );
  }
}
