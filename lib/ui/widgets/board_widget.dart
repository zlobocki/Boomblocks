import 'package:flutter/material.dart';

import '../../models/cell.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';
import '../../theme/game_assets.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.board,
    required this.cellSize,
    this.previewShape,
    this.previewRow,
    this.previewCol,
    this.previewValid = false,
    this.dynamiteHoverRow,
    this.dynamiteHoverCol,
  });

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final int? dynamiteHoverRow;
  final int? dynamiteHoverCol;

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
        child: Stack(
          children: [
            CustomPaint(
              size: Size(side, side),
              painter: _BoardPainter(
                board: board,
                cellSize: cellSize,
                previewShape: previewShape,
                previewRow: previewRow,
                previewCol: previewCol,
                previewValid: previewValid,
                dynamiteHoverRow: dynamiteHoverRow,
                dynamiteHoverCol: dynamiteHoverCol,
              ),
            ),
            for (var r = 0; r < BoardLogic.size; r++)
              for (var c = 0; c < BoardLogic.size; c++)
                if (board[r][c].hasGem)
                  Positioned(
                    left: c * cellSize + cellSize * 0.12,
                    top: r * cellSize + cellSize * 0.12,
                    width: cellSize * 0.76,
                    height: cellSize * 0.76,
                    child: Image.asset(
                      GameAssets.gem(board[r][c].gem!.name),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
          ],
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
    this.dynamiteHoverRow,
    this.dynamiteHoverCol,
  });

  final List<List<BoardCell>> board;
  final double cellSize;
  final PieceShape? previewShape;
  final int? previewRow;
  final int? previewCol;
  final bool previewValid;
  final int? dynamiteHoverRow;
  final int? dynamiteHoverCol;

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
        if (!board[r][c].filled) continue;
        _drawEarth(canvas, c * cellSize, r * cellSize);
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

    if (dynamiteHoverRow != null && dynamiteHoverCol != null) {
      final paint = Paint()
        ..color = BoomColors.dynamite.withValues(alpha: 0.35);
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

  void _drawEarth(Canvas canvas, double x, double y) {
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

    final speck = Paint()..color = BoomColors.rock.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(x + cellSize * 0.3, y + cellSize * 0.35), 2, speck);
    canvas.drawCircle(Offset(x + cellSize * 0.65, y + cellSize * 0.6), 1.5, speck);
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
