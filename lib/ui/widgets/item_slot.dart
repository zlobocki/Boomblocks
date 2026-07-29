import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inventory.dart';
import '../../theme/app_theme.dart';

class ItemSlot extends StatelessWidget {
  const ItemSlot({
    super.key,
    required this.label,
    required this.assetPath,
    required this.meter,
    required this.accent,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.dragging = false,
    this.enabled = true,
    this.showMax = false,
  });

  final String label;
  final String assetPath;
  final ItemMeter meter;
  final Color accent;
  final VoidCallback? onTap;
  final void Function(Offset global)? onDragStart;
  final void Function(Offset global)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool dragging;
  final bool enabled;
  final bool showMax;

  @override
  Widget build(BuildContext context) {
    final canUse = enabled && meter.count > 0;
    final canDrag = canUse && onDragStart != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canUse && onTap != null ? onTap : null,
              onPanStart: !canDrag
                  ? null
                  : (d) => onDragStart!(d.globalPosition),
              onPanUpdate: !canDrag || onDragUpdate == null
                  ? null
                  : (d) => onDragUpdate!(d.globalPosition),
              onPanEnd: !canDrag || onDragEnd == null ? null : (_) => onDragEnd!(),
              onPanCancel: !canDrag || onDragEnd == null ? null : onDragEnd,
              child: Opacity(
                opacity: dragging ? 0.35 : (canUse ? 1 : 0.45),
                child: _IconBadge(
                  assetPath: assetPath,
                  accent: accent,
                  count: meter.count,
                  maxCount: meter.maxCount,
                ),
              ),
            ),
            if (showMax)
              const Positioned(
                top: -10,
                right: -8,
                child: _MaxBadge(),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BoomColors.cream.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: meter.progressRatio,
                  minHeight: 7,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${meter.progress}/${meter.threshold}',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BoomColors.dust.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.assetPath,
    required this.accent,
    required this.count,
    required this.maxCount,
  });

  final String assetPath;
  final Color accent;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned(
            right: -4,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BoomColors.ink, width: 1.5),
              ),
              child: Text(
                '$count/$maxCount',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  const _MaxBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: BoomColors.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'MAX',
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
