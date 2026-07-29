import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/cell.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';
import '../../theme/game_assets.dart';

class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.board,
    required this.cellSize,
    this.previewShape,
    this.previewRow,
    this.previewCol,
    this.previewValid = false,
    this.highlightRows = const {},
    this.highlightCols = const {},
    this.explodingCells = const {},
    this.explosionEventId = 0,
    this.onShatterComplete,
    this.dynamiteHoverRow,
    this.dynamiteHoverCol,
  });

  /// Inset between the gold frame and the playable grid (avoids border clip).
  static const double contentInset = 3.0;

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final Set<int> highlightRows;
  final Set<int> highlightCols;
  final Set<(int, int)> explodingCells;
  final int explosionEventId;
  final VoidCallback? onShatterComplete;
  final int? dynamiteHoverRow;
  final int? dynamiteHoverCol;

  /// Total widget side length for a given cell size (grid + inset).
  static double outerSide(double cellSize) =>
      cellSize * BoardLogic.size + contentInset * 2;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shatter;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _shatter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener(_onShatterStatus);
  }

  void _onShatterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onShatterComplete?.call();
    }
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.explosionEventId != oldWidget.explosionEventId &&
        widget.explosionEventId > 0) {
      _shatter
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shatter.removeStatusListener(_onShatterStatus);
    _pulse.dispose();
    _shatter.dispose();
    super.dispose();
  }

  bool get _shatterActive =>
      _shatter.isAnimating ||
      (_shatter.value > 0 && _shatter.value < 1);

  @override
  Widget build(BuildContext context) {
    final gridSide = widget.cellSize * BoardLogic.size;
    final outer = BoardWidget.outerSide(widget.cellSize);
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shatter]),
      builder: (context, _) {
        final shatterT = Curves.easeOut.transform(_shatter.value);
        final shatterActive = _shatterActive;
        return Container(
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A140F), Color(0xFF0B0907)],
            ),
            border: Border.all(color: BoomColors.frameGold, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(BoardWidget.contentInset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: gridSide,
              height: gridSide,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  CustomPaint(
                    size: Size(gridSide, gridSide),
                    painter: _BoardPainter(
                      board: widget.board,
                      cellSize: widget.cellSize,
                      previewShape: widget.previewShape,
                      previewRow: widget.previewRow,
                      previewCol: widget.previewCol,
                      previewValid: widget.previewValid,
                      highlightRows: widget.highlightRows,
                      highlightCols: widget.highlightCols,
                      pulse: _pulse.value,
                      explodingCells: widget.explodingCells,
                      shatter: shatterT,
                      shatterActive: shatterActive,
                      dynamiteHoverRow: widget.dynamiteHoverRow,
                      dynamiteHoverCol: widget.dynamiteHoverCol,
                    ),
                  ),
                  for (var r = 0; r < BoardLogic.size; r++)
                    for (var c = 0; c < BoardLogic.size; c++)
                      if (widget.board[r][c].hasGem &&
                          !(shatterActive &&
                              widget.explodingCells.contains((r, c)) &&
                              shatterT > 0.2))
                        Positioned(
                          left: c * widget.cellSize + widget.cellSize * 0.12,
                          top: r * widget.cellSize + widget.cellSize * 0.12,
                          width: widget.cellSize * 0.76,
                          height: widget.cellSize * 0.76,
                          child: Opacity(
                            opacity: shatterActive &&
                                    widget.explodingCells.contains((r, c))
                                ? (1 - shatterT).clamp(0.0, 1.0)
                                : 1,
                            child: Image.asset(
                              GameAssets.gem(widget.board[r][c].gem!.name),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.cellSize,
    this.previewShape,
    this.previewRow,
    this.previewCol,
    this.previewValid = false,
    required this.highlightRows,
    required this.highlightCols,
    required this.pulse,
    required this.explodingCells,
    required this.shatter,
    required this.shatterActive,
    this.dynamiteHoverRow,
    this.dynamiteHoverCol,
  });

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final Set<int> highlightRows;
  final Set<int> highlightCols;
  final double pulse;
  final Set<(int, int)> explodingCells;
  final double shatter;
  final bool shatterActive;
  final int? dynamiteHoverRow;
  final int? dynamiteHoverCol;

  @override
  void paint(Canvas canvas, Size size) {
    for (var r = 0; r < BoardLogic.size; r++) {
      for (var c = 0; c < BoardLogic.size; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize + 2,
          r * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );
        final highlighted =
            highlightRows.contains(r) || highlightCols.contains(c);
        _drawEmpty(canvas, rect, highlighted: highlighted);

        final marked = explodingCells.contains((r, c));
        final filled = board[r][c].filled;

        if (marked && shatterActive) {
          // Cleared cells are already empty in model; still draw shatter.
          _drawShatter(canvas, rect, shatter);
        } else if (marked && shatter >= 1) {
          // Hold final dust frame (e.g. disaster) so filled cells stay hidden.
          _drawShatter(canvas, rect, 1);
        } else if (filled) {
          _drawEarth(canvas, rect);
        }
      }
    }

    if (previewShape != null && previewRow != null && previewCol != null) {
      final color = previewValid
          ? BoomColors.gold.withValues(alpha: 0.42)
          : BoomColors.danger.withValues(alpha: 0.42);
      final paint = Paint()..color = color;
      for (final p in previewShape!.cells) {
        final x = (previewCol! + p.x) * cellSize;
        final y = (previewRow! + p.y) * cellSize;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, y + 2, cellSize - 4, cellSize - 4),
            const Radius.circular(6),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, y + 2, cellSize - 4, cellSize - 4),
            const Radius.circular(6),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = previewValid ? BoomColors.gold : BoomColors.danger,
        );
      }
    }

    if (dynamiteHoverRow != null && dynamiteHoverCol != null) {
      final paint = Paint()
        ..color = BoomColors.dynamite.withValues(alpha: 0.38);
      final r = dynamiteHoverRow!;
      final c = dynamiteHoverCol!;
      for (var rr = r - 1; rr <= r + 1; rr++) {
        for (var cc = c - 1; cc <= c + 1; cc++) {
          if (rr < 0 ||
              rr >= BoardLogic.size ||
              cc < 0 ||
              cc >= BoardLogic.size) {
            continue;
          }
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cc * cellSize + 1,
                rr * cellSize + 1,
                cellSize - 2,
                cellSize - 2,
              ),
              const Radius.circular(4),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawEmpty(Canvas canvas, Rect rect, {required bool highlighted}) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: highlighted
            ? [
                Color.lerp(
                  const Color(0xFF3A1814),
                  const Color(0xFF7A2A22),
                  0.35 + pulse * 0.45,
                )!,
                Color.lerp(
                  const Color(0xFF2A100E),
                  const Color(0xFF5A1C18),
                  0.35 + pulse * 0.45,
                )!,
              ]
            : const [Color(0xFF2A221C), Color(0xFF17120E)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      paint,
    );
    if (highlighted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Color.lerp(
            const Color(0x66FF6B5A),
            const Color(0xCCFF3B2F),
            pulse,
          )!,
      );
    }
  }

  void _drawEarth(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6B4A32), Color(0xFF3A2618)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.2), const Radius.circular(6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66E8C07A),
    );
    final speck = Paint()..color = BoomColors.rock.withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.3, rect.top + rect.height * 0.35),
      2,
      speck,
    );
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.65, rect.top + rect.height * 0.6),
      1.5,
      speck,
    );
  }

  void _drawShatter(Canvas canvas, Rect rect, double t) {
    final rnd = math.Random((rect.left * 17 + rect.top * 31).toInt());
    final center = rect.center;
    for (var i = 0; i < 7; i++) {
      final angle = (i / 7) * math.pi * 2 + rnd.nextDouble();
      final dist = rect.width * (0.35 + rnd.nextDouble() * 0.55) * t;
      final chunk = Rect.fromCenter(
        center: center + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        width: rect.width * (0.22 - t * 0.08),
        height: rect.height * (0.18 - t * 0.06),
      );
      canvas.save();
      canvas.translate(chunk.center.dx, chunk.center.dy);
      canvas.rotate(angle * t);
      canvas.translate(-chunk.center.dx, -chunk.center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(chunk, const Radius.circular(3)),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF6B4A32),
            const Color(0x00C4A574),
            t,
          )!,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      rect.width * (0.2 + t * 0.55),
      Paint()
        ..color = Color.lerp(
          const Color(0x66C4A574),
          const Color(0x00C4A574),
          t,
        )!,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}

/// Renders a piece shape for the tray / drag feedback.
class PiecePreview extends StatelessWidget {
  const PiecePreview({
    super.key,
    required this.shape,
    required this.cellSize,
    this.hasRope = false,
    this.color,
  });

  final PieceShape shape;
  final double cellSize;
  final bool hasRope;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final w = shape.width * cellSize;
    final h = shape.height * cellSize;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _PiecePainter(
          shape: shape,
          cellSize: cellSize,
          hasRope: hasRope,
          color: color,
        ),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.shape,
    required this.cellSize,
    required this.hasRope,
    this.color,
  });

  final PieceShape shape;
  final double cellSize;
  final bool hasRope;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in shape.cells) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          p.x * cellSize + 2,
          p.y * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        ),
        const Radius.circular(6),
      );
      final fill = Paint()
        ..shader = LinearGradient(
          colors: color != null
              ? [color!, color!.withValues(alpha: 0.8)]
              : const [Color(0xFF7A5538), Color(0xFF3A2618)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, fill);
      if (hasRope) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = BoomColors.rope
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawRRect(
          rect.deflate(3),
          Paint()
            ..color = const Color(0xFFE8C07A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) => true;
}
