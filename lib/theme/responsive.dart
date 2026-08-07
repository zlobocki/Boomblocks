import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared breakpoints and sizing for phone vs tablet / landscape.
class BoomLayout {
  BoomLayout._();

  /// Material tablet breakpoint (shortest side).
  static const double tabletShortestSide = 600;

  static bool isTablet(Size size) => size.shortestSide >= tabletShortestSide;

  /// Side-by-side board + tray when the viewport is wide enough.
  static bool useWideGameLayout(Size size) =>
      size.width / size.height >= 1.15 && size.height >= 360;

  /// Max width for scrollable text screens (scoreboard, how-to-play).
  static double pageMaxWidth(Size size) => isTablet(size) ? 560.0 : 480.0;

  /// Max width for home CTAs on large screens.
  static double homeActionsMaxWidth(Size size) {
    if (isTablet(size)) return 420.0;
    return math.min(size.width - 32, 360.0);
  }

  /// Outer board size (including frame inset) for portrait / stacked layout.
  static double portraitBoardOuter(Size size) {
    final width = size.width;
    if (isTablet(size)) {
      return (width * 0.72).clamp(480.0, 680.0);
    }
    return (width - 32).clamp(280.0, 420.0);
  }

  /// Outer board size for wide / landscape layout.
  static double wideBoardOuter({
    required Size size,
    required double hudHeight,
    required EdgeInsets padding,
  }) {
    final availH =
        size.height - padding.vertical - hudHeight - 16;
    final availW = size.width * 0.58 - 24;
    return math.min(availH, availW).clamp(240.0, 640.0);
  }
}

/// Centers [child] and caps its width on tablets / large screens.
class BoomPageBody extends StatelessWidget {
  const BoomPageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 32),
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cap = maxWidth ?? BoomLayout.pageMaxWidth(size);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
