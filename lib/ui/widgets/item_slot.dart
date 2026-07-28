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
    required this.onDragStarted,
    required this.onDragEnded,
    this.enabled = true,
    this.showMax = false,
  });

  final String label;
  final String assetPath;
  final ItemMeter meter;
  final Color accent;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final bool enabled;
  final bool showMax;

  @override
  Widget build(BuildContext context) {
    final canDrag = enabled && meter.count > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            LongPressDraggable<String>(
              data: label.toLowerCase(),
              maxSimultaneousDrags: canDrag ? 1 : 0,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnded(),
              feedback: Material(
                color: Colors.transparent,
                child: _IconBadge(
                  assetPath: assetPath,
                  accent: accent,
                  count: meter.count,
                  dragging: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _IconBadge(
                  assetPath: assetPath,
                  accent: accent,
                  count: meter.count,
                ),
              ),
              child: _IconBadge(
                assetPath: assetPath,
                accent: accent,
                count: meter.count,
                dimmed: !canDrag,
              ),
            ),
            if (showMax)
              Positioned(
                top: -10,
                right: -8,
                child: const _MaxBadge(),
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
                  color: BoomColors.ink.withValues(alpha: 0.75),
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
                  color: BoomColors.ink.withValues(alpha: 0.55),
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
    this.dragging = false,
    this.dimmed = false,
  });

  final String assetPath;
  final Color accent;
  final int count;
  final bool dragging;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final size = dragging ? 72.0 : 60.0;
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: SizedBox(
        width: size,
        height: size,
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
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
