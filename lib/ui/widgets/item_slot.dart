import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inventory.dart';
import '../../theme/app_theme.dart';

class ItemSlot extends StatelessWidget {
  const ItemSlot({
    super.key,
    required this.label,
    required this.icon,
    required this.meter,
    required this.accent,
    required this.onDragStarted,
    required this.onDragEnded,
    this.enabled = true,
    this.showMax = false,
  });

  final String label;
  final IconData icon;
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
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnded(),
              feedback: Material(
                color: Colors.transparent,
                child: _IconBadge(
                  icon: icon,
                  accent: accent,
                  count: meter.count,
                  dragging: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _IconBadge(icon: icon, accent: accent, count: meter.count),
              ),
              child: _IconBadge(
                icon: icon,
                accent: accent,
                count: meter.count,
                dimmed: !canDrag,
              ),
            ),
            if (showMax)
              Positioned(
                top: -10,
                right: -8,
                child: _MaxBadge(),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
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
    required this.icon,
    required this.accent,
    required this.count,
    this.dragging = false,
    this.dimmed = false,
  });

  final IconData icon;
  final Color accent;
  final int count;
  final bool dragging;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: dragging ? 64 : 56,
        height: dragging ? 64 : 56,
        decoration: BoxDecoration(
          color: BoomColors.tray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: dragging ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: accent, size: 28)),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
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
      ),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
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
