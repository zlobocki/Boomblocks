import '../models/cell.dart';
import '../models/piece.dart';
import 'board_logic.dart';

/// Searches placement sequences for a tray of pieces on a board.
///
/// A "solution" is an ordered sequence that places every piece, applying line
/// clears after each placement (so early placements can open space for later
/// ones). Optionally the search may spend rope charges (rotate a piece to any
/// of its orientations) and dynamite charges (clear a 3×3 area, considered
/// only when no direct placement is possible — mirroring how a stuck player
/// would use it).
class PuzzleSolver {
  /// True if at least one solution exists.
  static bool isSolvable(
    List<List<BoardCell>> board,
    List<TrayPiece> pieces, {
    int ropeCharges = 0,
    int dynamiteCharges = 0,
    int nodeBudget = 120000,
  }) {
    return countSolutions(
          board,
          pieces,
          limit: 1,
          ropeCharges: ropeCharges,
          dynamiteCharges: dynamiteCharges,
          nodeBudget: nodeBudget,
        ) >
        0;
  }

  /// Counts distinct solution sequences up to [limit].
  ///
  /// Sequences that only swap two identical shapes are deduplicated. Returns
  /// early once [limit] is reached, so use a small limit for difficulty
  /// grading.
  static int countSolutions(
    List<List<BoardCell>> board,
    List<TrayPiece> pieces, {
    int limit = 1,
    int ropeCharges = 0,
    int dynamiteCharges = 0,
    int nodeBudget = 120000,
  }) {
    if (pieces.isEmpty) return 1;
    final budget = _Budget(nodeBudget);
    return _dfs(
      BoardLogic.cloneBoard(board),
      [for (final p in pieces) p.copy()],
      ropeCharges,
      dynamiteCharges,
      limit,
      budget,
    );
  }

  static int _dfs(
    List<List<BoardCell>> board,
    List<TrayPiece?> pieces,
    int ropeLeft,
    int dynLeft,
    int limit,
    _Budget budget,
  ) {
    final remaining = <int>[
      for (var i = 0; i < pieces.length; i++)
        if (pieces[i] != null) i,
    ];
    if (remaining.isEmpty) return 1;
    if (budget.exhausted) return 0;

    var found = 0;
    var anyPlacement = false;
    final seenShapes = <String>{};

    for (final i in remaining) {
      final piece = pieces[i]!;
      // Identical leftover shapes produce identical subtrees — search once.
      if (!seenShapes.add(_sig(piece.shape))) continue;

      final orientations = _orientations(piece.shape);
      for (var oi = 0; oi < orientations.length; oi++) {
        final needsRope = oi > 0 && !piece.hasRope;
        if (needsRope && ropeLeft <= 0) continue;
        final shape = orientations[oi];

        for (var r = 0; r <= BoardLogic.size - shape.height; r++) {
          for (var c = 0; c <= BoardLogic.size - shape.width; c++) {
            if (!budget.take()) return found;
            if (!BoardLogic.canPlace(board, shape, r, c)) continue;
            anyPlacement = true;

            final next = BoardLogic.cloneBoard(board);
            BoardLogic.placePiece(next, shape, r, c);
            BoardLogic.clearCompletedLines(next);

            final saved = pieces[i];
            pieces[i] = null;
            found += _dfs(
              next,
              pieces,
              ropeLeft - (needsRope ? 1 : 0),
              dynLeft,
              limit - found,
              budget,
            );
            pieces[i] = saved;
            if (found >= limit) return found;
          }
        }
      }
    }

    // Dynamite only helps when the player is stuck — same rule here keeps the
    // branching factor manageable.
    if (!anyPlacement && dynLeft > 0) {
      for (var r = 0; r < BoardLogic.size; r++) {
        for (var c = 0; c < BoardLogic.size; c++) {
          if (!_dynamiteUseful(board, r, c)) continue;
          if (!budget.take()) return found;
          final next = BoardLogic.cloneBoard(board);
          BoardLogic.clearDynamite(next, r, c);
          found += _dfs(
            next,
            pieces,
            ropeLeft,
            dynLeft - 1,
            limit - found,
            budget,
          );
          if (found >= limit) return found;
        }
      }
    }

    return found;
  }

  static bool _dynamiteUseful(List<List<BoardCell>> board, int row, int col) {
    for (var r = row - 1; r <= row + 1; r++) {
      for (var c = col - 1; c <= col + 1; c++) {
        if (r < 0 || r >= BoardLogic.size || c < 0 || c >= BoardLogic.size) {
          continue;
        }
        if (board[r][c].filled) return true;
      }
    }
    return false;
  }

  static List<PieceShape> _orientations(PieceShape shape) {
    final result = <PieceShape>[shape];
    final seen = {_sig(shape)};
    var cur = shape;
    for (var i = 0; i < 3; i++) {
      cur = cur.rotated90();
      if (seen.add(_sig(cur))) result.add(cur);
    }
    return result;
  }

  static String _sig(PieceShape shape) {
    final cells = shape.cells.map((p) => '${p.x},${p.y}').toList()..sort();
    return cells.join(';');
  }
}

class _Budget {
  _Budget(this.remaining);

  int remaining;

  bool get exhausted => remaining <= 0;

  bool take() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}
