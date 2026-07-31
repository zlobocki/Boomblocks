import 'dart:math';

/// A tetromino-like shape as cell offsets from origin.
class PieceShape {
  const PieceShape(this.id, this.cells);

  final String id;
  final List<Point<int>> cells;

  int get width {
    if (cells.isEmpty) return 0;
    return cells.map((c) => c.x).reduce(max) - cells.map((c) => c.x).reduce(min) + 1;
  }

  int get height {
    if (cells.isEmpty) return 0;
    return cells.map((c) => c.y).reduce(max) - cells.map((c) => c.y).reduce(min) + 1;
  }

  /// Normalize so min x/y are 0.
  PieceShape normalized() {
    if (cells.isEmpty) return this;
    final minX = cells.map((c) => c.x).reduce(min);
    final minY = cells.map((c) => c.y).reduce(min);
    return PieceShape(
      id,
      cells.map((c) => Point(c.x - minX, c.y - minY)).toList(),
    );
  }

  PieceShape rotated90() {
    // (x, y) -> (y, -x) then normalize
    final rotated = cells.map((c) => Point(c.y, -c.x)).toList();
    return PieceShape(id, rotated).normalized();
  }
}

class TrayPiece {
  TrayPiece({
    required this.id,
    required this.shape,
    this.hasRope = false,
  });

  final String id;
  PieceShape shape;
  bool hasRope;

  TrayPiece copy() => TrayPiece(id: id, shape: shape, hasRope: hasRope);

  void rotate() {
    if (!hasRope) return;
    shape = shape.rotated90();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shapeId': shape.id,
        'cells': shape.cells.map((c) => {'x': c.x, 'y': c.y}).toList(),
        'hasRope': hasRope,
      };

  factory TrayPiece.fromJson(Map<String, dynamic> json) {
    final cells = (json['cells'] as List)
        .map((e) => Point<int>(e['x'] as int, e['y'] as int))
        .toList();
    return TrayPiece(
      id: json['id'] as String,
      shape: PieceShape(json['shapeId'] as String? ?? 'custom', cells),
      hasRope: json['hasRope'] as bool? ?? false,
    );
  }
}

class PieceCatalog {
  static final monomino = PieceShape('mono', [const Point(0, 0)]);

  static final dominoH = PieceShape('domino_h', [
    const Point(0, 0),
    const Point(1, 0),
  ]);

  static final trominoI = PieceShape('tromino_i', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
  ]);

  static final trominoL = PieceShape('tromino_l', [
    const Point(0, 0),
    const Point(0, 1),
    const Point(1, 1),
  ]);

  static final tetrominoI = PieceShape('I', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
    const Point(3, 0),
  ]);

  static final tetrominoO = PieceShape('O', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(0, 1),
    const Point(1, 1),
  ]);

  static final tetrominoT = PieceShape('T', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
    const Point(1, 1),
  ]);

  static final tetrominoL = PieceShape('L', [
    const Point(0, 0),
    const Point(0, 1),
    const Point(0, 2),
    const Point(1, 2),
  ]);

  static final tetrominoJ = PieceShape('J', [
    const Point(1, 0),
    const Point(1, 1),
    const Point(1, 2),
    const Point(0, 2),
  ]);

  static final tetrominoS = PieceShape('S', [
    const Point(1, 0),
    const Point(2, 0),
    const Point(0, 1),
    const Point(1, 1),
  ]);

  static final tetrominoZ = PieceShape('Z', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(1, 1),
    const Point(2, 1),
  ]);

  /// Full 3×3 square (9 cells).
  static final square3 = PieceShape('square3', [
    for (var y = 0; y < 3; y++)
      for (var x = 0; x < 3; x++) Point<int>(x, y),
  ]);

  /// 3×3-bounded L pentomino (5 cells) — base orientation.
  static final bigL0 = PieceShape('bigL0', [
    const Point(0, 0),
    const Point(0, 1),
    const Point(0, 2),
    const Point(1, 2),
    const Point(2, 2),
  ]);

  static final bigL1 = PieceShape('bigL1', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
    const Point(0, 1),
    const Point(0, 2),
  ]);

  static final bigL2 = PieceShape('bigL2', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
    const Point(2, 1),
    const Point(2, 2),
  ]);

  static final bigL3 = PieceShape('bigL3', [
    const Point(2, 0),
    const Point(2, 1),
    const Point(0, 2),
    const Point(1, 2),
    const Point(2, 2),
  ]);

  static List<PieceShape> get bigLAll => [bigL0, bigL1, bigL2, bigL3];

  /// 3-wide × 2-tall rectangle (6 cells).
  static final rect3x2 = PieceShape('rect3x2', [
    for (var y = 0; y < 2; y++)
      for (var x = 0; x < 3; x++) Point<int>(x, y),
  ]);

  /// 2-wide × 3-tall rectangle (6 cells).
  static final rect2x3 = PieceShape('rect2x3', [
    for (var y = 0; y < 3; y++)
      for (var x = 0; x < 2; x++) Point<int>(x, y),
  ]);

  /// Two blocks on a diagonal.
  static final diag2 = PieceShape('diag2', [
    const Point(0, 0),
    const Point(1, 1),
  ]);

  /// Three blocks on a diagonal.
  static final diag3 = PieceShape('diag3', [
    const Point(0, 0),
    const Point(1, 1),
    const Point(2, 2),
  ]);

  /// Straight pentomino — 5×1 bar.
  static final pentominoI = PieceShape('I5', [
    for (var x = 0; x < 5; x++) Point<int>(x, 0),
  ]);

  /// T pentomino in a 3×3 footprint (5 cells).
  static final pentominoT = PieceShape('T5', [
    const Point(0, 0),
    const Point(1, 0),
    const Point(2, 0),
    const Point(1, 1),
    const Point(1, 2),
  ]);

  /// Plus / cross pentomino in a 3×3 footprint (5 cells).
  static final plus = PieceShape('plus', [
    const Point(1, 0),
    const Point(0, 1),
    const Point(1, 1),
    const Point(2, 1),
    const Point(1, 2),
  ]);

  static List<PieceShape> get easy => [
        monomino,
        dominoH,
        trominoI,
        trominoL,
        tetrominoO,
        tetrominoI,
        tetrominoT,
        bigL0,
        bigL1,
        diag2,
      ];

  static List<PieceShape> get medium => [
        trominoI,
        trominoL,
        tetrominoO,
        tetrominoI,
        tetrominoT,
        tetrominoL,
        tetrominoJ,
        square3,
        rect3x2,
        rect2x3,
        diag2,
        diag3,
        ...bigLAll,
      ];

  /// Late-game bag. Only one `bigL` base shape is listed — deals already apply
  /// random rotations — so L-pentominoes aren't over-weighted vs new shapes.
  static List<PieceShape> get hard => [
        tetrominoI,
        tetrominoT,
        tetrominoL,
        tetrominoJ,
        tetrominoS,
        tetrominoZ,
        square3,
        square3,
        rect3x2,
        rect2x3,
        diag3,
        diag3,
        bigL0,
        pentominoI,
        pentominoI,
        pentominoT,
        pentominoT,
        plus,
        plus,
      ];
}
