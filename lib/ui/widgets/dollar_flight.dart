import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Animates dollar amounts from board gem cells up to the cash HUD chip.
class DollarFlightLayer extends StatefulWidget {
  const DollarFlightLayer({
    super.key,
    required this.flights,
    required this.eventId,
    required this.boardKey,
    required this.scoreKey,
    required this.rootKey,
    required this.cellSize,
    required this.onFinished,
  });

  final List<CollectedGemFlight> flights;
  final int eventId;
  final GlobalKey boardKey;
  final GlobalKey scoreKey;
  final GlobalKey rootKey;
  final double cellSize;
  final VoidCallback onFinished;

  @override
  State<DollarFlightLayer> createState() => _DollarFlightLayerState();
}

class CollectedGemFlight {
  CollectedGemFlight({
    required this.row,
    required this.col,
    required this.points,
  });

  final int row;
  final int col;
  final int points;
}

class _DollarFlightLayerState extends State<DollarFlightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_FlightPath> _paths = [];
  int _lastEventId = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildPaths());
  }

  @override
  void didUpdateWidget(covariant DollarFlightLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId != _lastEventId && widget.flights.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildPaths());
    }
  }

  void _rebuildPaths() {
    if (widget.flights.isEmpty) return;
    final rootBox =
        widget.rootKey.currentContext?.findRenderObject() as RenderBox?;
    final boardBox =
        widget.boardKey.currentContext?.findRenderObject() as RenderBox?;
    final scoreBox =
        widget.scoreKey.currentContext?.findRenderObject() as RenderBox?;
    if (rootBox == null || boardBox == null || scoreBox == null) return;

    final boardOrigin = boardBox.localToGlobal(Offset.zero);
    final scoreOrigin = scoreBox.localToGlobal(Offset.zero);
    final scoreCenter = Offset(
      scoreOrigin.dx + scoreBox.size.width / 2,
      scoreOrigin.dy + scoreBox.size.height / 2,
    );

    final paths = <_FlightPath>[];
    for (final f in widget.flights) {
      final startGlobal = Offset(
        boardOrigin.dx + (f.col + 0.5) * widget.cellSize,
        boardOrigin.dy + (f.row + 0.5) * widget.cellSize,
      );
      paths.add(_FlightPath(
        start: rootBox.globalToLocal(startGlobal),
        end: rootBox.globalToLocal(scoreCenter),
        points: f.points,
      ));
    }

    setState(() {
      _paths = paths;
      _lastEventId = widget.eventId;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_paths.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              for (final path in _paths)
                _FlightLabel(
                  path: path,
                  t: Curves.easeInOutCubic.transform(_controller.value),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FlightPath {
  _FlightPath({
    required this.start,
    required this.end,
    required this.points,
  });

  final Offset start;
  final Offset end;
  final int points;
}

class _FlightLabel extends StatelessWidget {
  const _FlightLabel({required this.path, required this.t});

  final _FlightPath path;
  final double t;

  @override
  Widget build(BuildContext context) {
    // Slight arc upward then into the cash chip.
    final mid = Offset(
      (path.start.dx + path.end.dx) / 2,
      (path.start.dy + path.end.dy) / 2 - 60,
    );
    final pos = _quad(path.start, mid, path.end, t);
    final opacity = t < 0.15
        ? t / 0.15
        : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
    final scale = 1.0 + 0.25 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);

    return Positioned(
      left: pos.dx - 28,
      top: pos.dy - 12,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Text(
            '+\$${path.points}',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: BoomColors.success,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }
}
