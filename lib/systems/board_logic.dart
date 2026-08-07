import 'dart:math';

import '../models/cell.dart';
import '../models/gem.dart';
import '../models/piece.dart';

class CollectedGem {
  CollectedGem({
    required this.row,
    required this.col,
    required this.baseValue,
    required this.points,
  });

  final int row;
  final int col;
  final int baseValue;
  /// Points awarded for this gem after line multiplier.
  final int points;
}

class ClearResult {
  ClearResult({
    required this.rowsCleared,
    required this.colsCleared,
    required this.gemValueSum,
    required this.clearedCells,
    this.collectedGems = const [],
  });

  final int rowsCleared;
  final int colsCleared;
  final int gemValueSum;
  final List<Point<int>> clearedCells;
  final List<CollectedGem> collectedGems;

  int get linesCleared => rowsCleared + colsCleared;

  int get multiplier => linesCleared <= 0 ? 1 : linesCleared;

  int get score {
    if (gemValueSum <= 0) return 0;
    return multiplier * gemValueSum;
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
    TrayPiece piece, {
    bool allRotations = false,
  }) {
    final orientations = <PieceShape>[piece.shape];
    if (piece.hasRope || allRotations) {
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

  /// Rows/cols that would complete if [shape] were placed at origin.
  static ({List<int> rows, List<int> cols}) previewClearLines(
    List<List<BoardCell>> board,
    PieceShape shape,
    int originRow,
    int originCol,
  ) {
    if (!canPlace(board, shape, originRow, originCol)) {
      return (rows: <int>[], cols: <int>[]);
    }
    final clone = cloneBoard(board);
    placePiece(clone, shape, originRow, originCol);
    final rows = <int>[];
    final cols = <int>[];
    for (var r = 0; r < size; r++) {
      if (clone[r].every((c) => c.filled)) rows.add(r);
    }
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (!clone[r][c].filled) {
          full = false;
          break;
        }
      }
      if (full) cols.add(c);
    }
    return (rows: rows, cols: cols);
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
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        cleared.add(Point(c, r));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        cleared.add(Point(c, r));
      }
    }

    final gemCells = <CollectedGem>[];
    var gemSum = 0;
    for (final p in cleared) {
      final cell = board[p.y][p.x];
      if (cell.hasGem) {
        gemSum += cell.gem!.value;
        gemCells.add(CollectedGem(
          row: p.y,
          col: p.x,
          baseValue: cell.gem!.value,
          points: cell.gem!.value,
        ));
      }
    }

    for (final p in cleared) {
      board[p.y][p.x].clear();
    }

    final lines = fullRows.length + fullCols.length;
    final mult = lines <= 0 ? 1 : lines;
    final gems = [
      for (final g in gemCells)
        CollectedGem(
          row: g.row,
          col: g.col,
          baseValue: g.baseValue,
          points: g.baseValue * mult,
        ),
    ];

    return ClearResult(
      rowsCleared: fullRows.length,
      colsCleared: fullCols.length,
      gemValueSum: gemSum,
      clearedCells: cleared.toList(),
      collectedGems: gems,
    );
  }

  /// Clears a 3x3 centered on (row, col). Returns gem sum cleared.
  static ClearResult clearDynamite(
    List<List<BoardCell>> board,
    int row,
    int col,
  ) {
    final gemCells = <CollectedGem>[];
    var gemSum = 0;
    final cleared = <Point<int>>[];
    for (var r = row - 1; r <= row + 1; r++) {
      for (var c = col - 1; c <= col + 1; c++) {
        if (r < 0 || r >= size || c < 0 || c >= size) continue;
        final cell = board[r][c];
        if (!cell.filled) continue;
        if (cell.hasGem) {
          gemSum += cell.gem!.value;
          gemCells.add(CollectedGem(
            row: r,
            col: c,
            baseValue: cell.gem!.value,
            points: cell.gem!.value,
          ));
        }
        cell.clear();
        cleared.add(Point(c, r));
      }
    }
    final followUp = clearCompletedLines(board);
    final mult = followUp.multiplier;
    // Dynamite gems use follow-up line multiplier when lines also clear.
    final dynMult = followUp.linesCleared > 0 ? mult : 1;
    final gems = [
      for (final g in gemCells)
        CollectedGem(
          row: g.row,
          col: g.col,
          baseValue: g.baseValue,
          points: g.baseValue * dynMult,
        ),
      ...followUp.collectedGems,
    ];
    return ClearResult(
      rowsCleared: followUp.rowsCleared,
      colsCleared: followUp.colsCleared,
      gemValueSum: gemSum + followUp.gemValueSum,
      clearedCells: [...cleared, ...followUp.clearedCells],
      collectedGems: gems,
    );
  }

  static bool isEmpty(List<List<BoardCell>> board) {
    for (final row in board) {
      for (final cell in row) {
        if (cell.filled) return false;
      }
    }
    return true;
  }

  static int filledCount(List<List<BoardCell>> board) {
    var n = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell.filled) n++;
      }
    }
    return n;
  }

  /// Scatter earth blocks so the opening board is already a puzzle.
  /// Never fills a complete row or column.
  static void prefillBoard(
    List<List<BoardCell>> board, {
    int targetCells = 22,
    Random? random,
  }) {
    final rng = random ?? Random();
    final shapes = [
      PieceCatalog.dominoH,
      PieceCatalog.trominoI,
      PieceCatalog.trominoL,
      PieceCatalog.tetrominoO,
      PieceCatalog.tetrominoT,
      PieceCatalog.tetrominoL,
      PieceCatalog.bigL0,
    ];

    var placed = 0;
    var attempts = 0;
    while (placed < targetCells && attempts < 200) {
      attempts++;
      final shape = shapes[rng.nextInt(shapes.length)];
      var s = shape;
      final turns = rng.nextInt(4);
      for (var t = 0; t < turns; t++) {
        s = s.rotated90();
      }
      final row = rng.nextInt(size);
      final col = rng.nextInt(size);
      if (!canPlace(board, s, row, col)) continue;

      // Tentatively place, reject if it completes a line.
      placePiece(board, s, row, col);
      var completesLine = false;
      for (var r = 0; r < size; r++) {
        if (board[r].every((c) => c.filled)) {
          completesLine = true;
          break;
        }
      }
      if (!completesLine) {
        for (var c = 0; c < size; c++) {
          var full = true;
          for (var r = 0; r < size; r++) {
            if (!board[r][c].filled) {
              full = false;
              break;
            }
          }
          if (full) {
            completesLine = true;
            break;
          }
        }
      }
      if (completesLine) {
        // Undo
        for (final p in s.cells) {
          board[row + p.y][col + p.x].clear();
        }
        continue;
      }
      placed += s.cells.length;
    }
  }
}
