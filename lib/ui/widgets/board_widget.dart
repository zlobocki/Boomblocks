import 'package:flutter/material.dart';

import '../../models/cell.dart';
import '../../models/gem.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.board,
    required this.cellSize,
    this.previewShape,
    this.previewRow,
    this.previewCol,
    this.previewValid = false,
    this.dynamiteHover,
    this.onCellTap,
  });

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final Offset? dynamiteHover; // board-local
  final void Function(int row, int col)? onCellTap;

  @override
  Widget build(BuildContext context) {
    final side = cellSize * BoardLogic.size;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E0C8), BoomColors.boardBg],
        ),
        boxShadow: [
          BoxShadow(
            color: BoomColors.ink.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTapUp: onCellTap == null
              ? null
              : (d) {
                  final c = (d.localPosition.dx / cellSize).floor();
                  final r = (d.localPosition.dy / cellSize).floor();
                  if (r >= 0 &&
                      r < BoardLogic.size &&
                      c >= 0 &&
                      c < BoardLogic.size) {
                    onCellTap!(r, c);
                  }
                },
          child: CustomPaint(
            size: Size(side, side),
            painter: _BoardPainter(
              board: board,
              cellSize: cellSize,
              previewShape: previewShape,
              previewRow: previewRow,
              previewCol: previewCol,
              previewValid: previewValid,
              dynamiteHover: dynamiteHover,
            ),
          ),
        ),
      ),
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
    this.dynamiteHover,
  });

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final Offset? dynamiteHover;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = BoomColors.boardLine
      ..strokeWidth = 1;

    for (var i = 0; i <= BoardLogic.size; i++) {
      final o = i * cellSize;
      canvas.drawLine(Offset(o, 0), Offset(o, size.height), gridPaint);
      canvas.drawLine(Offset(0, o), Offset(size.width, o), gridPaint);
    }

    for (var r = 0; r < BoardLogic.size; r++) {
      for (var c = 0; c < BoardLogic.size; c++) {
        final cell = board[r][c];
        if (!cell.filled) continue;
        _drawEarth(canvas, c * cellSize, r * cellSize, cell);
      }
    }

    if (previewShape != null && previewRow != null && previewCol != null) {
      final color = previewValid
          ? BoomColors.success.withValues(alpha: 0.45)
          : BoomColors.danger.withValues(alpha: 0.45);
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
      }
    }

    if (dynamiteHover != null) {
      final c = (dynamiteHover!.dx / cellSize).floor();
      final r = (dynamiteHover!.dy / cellSize).floor();
      final paint = Paint()
        ..color = BoomColors.dynamite.withValues(alpha: 0.35);
      for (var rr = r - 1; rr <= r + 1; rr++) {
        for (var cc = c - 1; cc <= c + 1; cc++) {
          if (rr < 0 || rr >= BoardLogic.size || cc < 0 || cc >= BoardLogic.size) {
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

  void _drawEarth(Canvas canvas, double x, double y, BoardCell cell) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 2, y + 2, cellSize - 4, cellSize - 4),
      const Radius.circular(7),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD2B48C), BoomColors.earth, Color(0xFFA67C52)],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);

    // rock speckles
    final speck = Paint()..color = BoomColors.rock.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(x + cellSize * 0.3, y + cellSize * 0.35), 2, speck);
    canvas.drawCircle(Offset(x + cellSize * 0.65, y + cellSize * 0.6), 1.5, speck);

    if (cell.hasGem) {
      _drawGem(canvas, x, y, cell.gem!);
    }
  }

  void _drawGem(Canvas canvas, double x, double y, GemType gem) {
    final cx = x + cellSize / 2;
    final cy = y + cellSize / 2;
    final color = switch (gem) {
      GemType.coal => const Color(0xFF3A3A3A),
      GemType.silver => const Color(0xFFC0C0C0),
      GemType.gold => const Color(0xFFFFD700),
      GemType.emerald => const Color(0xFF2ECC71),
      GemType.ruby => const Color(0xFFE74C3C),
      GemType.diamond => const Color(0xFF7FDBFF),
    };
    final path = Path()
      ..moveTo(cx, cy - cellSize * 0.28)
      ..lineTo(cx + cellSize * 0.22, cy)
      ..lineTo(cx, cy + cellSize * 0.28)
      ..lineTo(cx - cellSize * 0.22, cy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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
        painter: _PiecePainter(shape: shape, cellSize: cellSize, hasRope: hasRope, color: color),
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
              : const [Color(0xFFD2B48C), Color(0xFFA67C52)],
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
        // rope dashes
        canvas.drawRRect(
          rect.deflate(3),
          Paint()
            ..color = const Color(0xFF8B6914)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) => true;
}
