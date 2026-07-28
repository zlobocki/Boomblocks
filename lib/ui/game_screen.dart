import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_controller.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';
import '../../theme/game_assets.dart';
import 'scoreboard_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/dollar_flight.dart';
import 'widgets/hud.dart';
import 'widgets/item_slot.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.continuing = false,
  });

  final GameController controller;
  final bool continuing;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  PieceShape? _previewShape;
  int? _previewRow;
  int? _previewCol;
  bool _previewValid = false;
  int? _dynamiteRow;
  int? _dynamiteCol;

  bool _draggingRope = false;
  bool _draggingDynamite = false;
  int? _ropeHoverTrayIndex;
  bool _showRopeMax = false;
  bool _showDynMax = false;
  bool _gameOverShown = false;

  int? _dragTrayIndex;
  Offset? _pointerGlobal;

  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _rootKey = GlobalKey();
  final GlobalKey _scoreKey = GlobalKey();
  final List<GlobalKey> _trayKeys = List.generate(3, (_) => GlobalKey());

  double _cellSize = 40;
  int _lastFlightEventId = 0;
  List<CollectedGemFlight> _activeFlights = [];

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.init(forceNew: !widget.continuing);
      if (c.status == GameStatus.gameOver && mounted) {
        _showGameOver();
      }
    });
  }

  @override
  void dispose() {
    c.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {
      if (c.clearEventId != _lastFlightEventId &&
          c.pendingGemFlights.isNotEmpty) {
        _lastFlightEventId = c.clearEventId;
        _activeFlights = [
          for (final g in c.pendingGemFlights)
            CollectedGemFlight(row: g.row, col: g.col, points: g.points),
        ];
        c.consumeGemFlights();
      }
      if (c.maxToast != null) {
        _showRopeMax = c.inventory.rope.count >= c.inventory.rope.maxCount;
        _showDynMax =
            c.inventory.dynamite.count >= c.inventory.dynamite.maxCount;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showRopeMax = false;
              _showDynMax = false;
            });
            c.clearToasts();
          }
        });
      }
    });
    if (c.status == GameStatus.gameOver && !_gameOverShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }
  }

  RenderBox? _boardBox() =>
      _boardKey.currentContext?.findRenderObject() as RenderBox?;

  Offset? _toRootLocal(Offset global) {
    final box = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  void _updatePieceSnap(Offset global, TrayPiece piece) {
    final box = _boardBox();
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(global);
    final lift = _cellSize * (piece.shape.height + 0.55);
    final anchorX = local.dx - (piece.shape.width * _cellSize) / 2;
    final anchorY = local.dy - lift;

    var originCol = (anchorX / _cellSize).round();
    var originRow = (anchorY / _cellSize).round();
    originCol = originCol.clamp(0, BoardLogic.size - piece.shape.width);
    originRow = originRow.clamp(0, BoardLogic.size - piece.shape.height);

    final pad = _cellSize * 2;
    final outside = local.dx < -pad ||
        local.dy < -pad ||
        local.dx > box.size.width + pad ||
        local.dy > box.size.height + pad;

    setState(() {
      _pointerGlobal = global;
      if (outside) {
        _previewShape = null;
        _previewRow = null;
        _previewCol = null;
        _previewValid = false;
      } else {
        _previewShape = piece.shape;
        _previewRow = originRow;
        _previewCol = originCol;
        _previewValid =
            BoardLogic.canPlace(c.board, piece.shape, originRow, originCol);
      }
    });
  }

  void _updateDynamiteSnap(Offset global) {
    final box = _boardBox();
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    setState(() {
      _pointerGlobal = global;
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > box.size.width ||
          local.dy > box.size.height) {
        _dynamiteRow = null;
        _dynamiteCol = null;
      } else {
        _dynamiteCol =
            (local.dx / _cellSize).floor().clamp(0, BoardLogic.size - 1);
        _dynamiteRow =
            (local.dy / _cellSize).floor().clamp(0, BoardLogic.size - 1);
      }
    });
  }

  void _updateRopeHover(Offset global) {
    int? hit;
    for (var i = 0; i < _trayKeys.length; i++) {
      final box =
          _trayKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      final rect = topLeft & box.size;
      if (rect.contains(global)) {
        final piece = c.tray[i];
        if (piece != null && !piece.hasRope) {
          hit = i;
        }
        break;
      }
    }
    setState(() {
      _pointerGlobal = global;
      _ropeHoverTrayIndex = hit;
    });
  }

  void _endRopeDrag() {
    final idx = _ropeHoverTrayIndex;
    if (idx != null) {
      c.applyRopeToPiece(idx);
    }
    _clearDrag();
  }

  void _clearDrag() {
    setState(() {
      _previewShape = null;
      _previewRow = null;
      _previewCol = null;
      _previewValid = false;
      _dynamiteRow = null;
      _dynamiteCol = null;
      _draggingRope = false;
      _draggingDynamite = false;
      _ropeHoverTrayIndex = null;
      _dragTrayIndex = null;
      _pointerGlobal = null;
    });
  }

  void _endPieceDrag() {
    final idx = _dragTrayIndex;
    if (idx != null &&
        _previewValid &&
        _previewRow != null &&
        _previewCol != null) {
      c.placePiece(idx, _previewRow!, _previewCol!);
    }
    _clearDrag();
  }

  void _endDynamiteDrag() {
    if (_dynamiteRow != null && _dynamiteCol != null) {
      c.useDynamite(_dynamiteRow!, _dynamiteCol!);
    }
    _clearDrag();
  }

  Future<void> _showGameOver() async {
    if (!mounted || _gameOverShown) return;
    _gameOverShown = true;
    final qualifies = await c.qualifiesForScoreboard();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: BoomColors.hud,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Game Over',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cash: \$${c.score}',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (qualifies) ...[
                const SizedBox(height: 12),
                Text(
                  'You made the top 10! Enter your name:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    hintText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (qualifies) await c.submitHighScore(nameCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  _gameOverShown = false;
                  c.newGame();
                }
              },
              child: const Text('Play again'),
            ),
            TextButton(
              onPressed: () async {
                if (qualifies) await c.submitHighScore(nameCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Home'),
            ),
          ],
        );
      },
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BoomColors.hud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.leaderboard_rounded),
              title: const Text('Top 10'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScoreboardScreen(controller: c),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('New game'),
              onTap: () {
                Navigator.pop(ctx);
                c.newGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!c.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final boardSide = (width - 32).clamp(280.0, 420.0);
    _cellSize = boardSide / BoardLogic.size;

    final localPointer =
        _pointerGlobal == null ? null : _toRootLocal(_pointerGlobal!);
    final draggingPiece =
        _dragTrayIndex != null ? c.tray[_dragTrayIndex!] : null;

    return Scaffold(
      body: Container(
        key: _rootKey,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BoomColors.skyTop,
              BoomColors.skyBottom,
              Color(0xFFE8C9A0),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  GameHud(
                    score: c.score,
                    round: c.round,
                    lootProgress: c.gemsCollectedTowardReset,
                    lootGoal: GameController.lootResetAt,
                    scoreToast: c.lastScoreToast,
                    onMenu: _openMenu,
                    scoreKey: _scoreKey,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: KeyedSubtree(
                        key: _boardKey,
                        child: BoardWidget(
                          board: c.board,
                          cellSize: _cellSize,
                          previewShape: _previewShape,
                          previewRow: _previewRow,
                          previewCol: _previewCol,
                          previewValid: _previewValid,
                          dynamiteHoverRow:
                              _draggingDynamite ? _dynamiteRow : null,
                          dynamiteHoverCol:
                              _draggingDynamite ? _dynamiteCol : null,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BoomColors.tray.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: BoomColors.earth.withValues(alpha: 0.45),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 6.0;
                          final slotW = (constraints.maxWidth - gap * 2) / 3;
                          const maxCells = 4;
                          final pieceCell = ((slotW - 8) / maxCells)
                              .clamp(12.0, _cellSize * 0.7);
                          return Row(
                            children: List.generate(3, (i) {
                              final piece = c.tray[i];
                              return Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                                child: SizedBox(
                                  key: _trayKeys[i],
                                  width: slotW,
                                  child: _TraySlot(
                                    piece: piece,
                                    slotSize: slotW,
                                    cellSize: pieceCell,
                                    highlighted: _draggingRope &&
                                        _ropeHoverTrayIndex == i,
                                    dragging: _dragTrayIndex == i,
                                    onTap: piece != null && piece.hasRope
                                        ? () => c.rotatePiece(i)
                                        : null,
                                    onDragStart: (global) {
                                      if (piece == null) return;
                                      setState(() {
                                        _dragTrayIndex = i;
                                        _pointerGlobal = global;
                                      });
                                      _updatePieceSnap(global, piece);
                                    },
                                    onDragUpdate: (global) {
                                      final p = c.tray[i];
                                      if (p == null) return;
                                      _updatePieceSnap(global, p);
                                    },
                                    onDragEnd: _endPieceDrag,
                                    onDragCancel: _clearDrag,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ItemSlot(
                          label: 'Rope',
                          assetPath: GameAssets.rope,
                          meter: c.inventory.rope,
                          accent: BoomColors.rope,
                          showMax: _showRopeMax,
                          dragging: _draggingRope,
                          onDragStart: (global) {
                            setState(() {
                              _draggingRope = true;
                              _pointerGlobal = global;
                            });
                            _updateRopeHover(global);
                          },
                          onDragUpdate: _updateRopeHover,
                          onDragEnd: _endRopeDrag,
                        ),
                        const SizedBox(width: 28),
                        ItemSlot(
                          label: 'Dynamite',
                          assetPath: GameAssets.dynamite,
                          meter: c.inventory.dynamite,
                          accent: BoomColors.dynamite,
                          showMax: _showDynMax,
                          dragging: _draggingDynamite,
                          onDragStart: (global) {
                            setState(() {
                              _draggingDynamite = true;
                              _pointerGlobal = global;
                            });
                            _updateDynamiteSnap(global);
                          },
                          onDragUpdate: _updateDynamiteSnap,
                          onDragEnd: _endDynamiteDrag,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating piece / item under finger
            if (draggingPiece != null && localPointer != null)
              Positioned(
                left: localPointer.dx -
                    (draggingPiece.shape.width * _cellSize) / 2,
                top: localPointer.dy -
                    _cellSize * (draggingPiece.shape.height + 0.55),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.95,
                    child: PiecePreview(
                      shape: draggingPiece.shape,
                      cellSize: _cellSize,
                      hasRope: draggingPiece.hasRope,
                    ),
                  ),
                ),
              ),
            if (_draggingDynamite && localPointer != null)
              Positioned(
                left: localPointer.dx - 36,
                top: localPointer.dy - 36,
                child: IgnorePointer(
                  child: Image.asset(
                    GameAssets.dynamite,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
            if (_draggingRope && localPointer != null)
              Positioned(
                left: localPointer.dx - 36,
                top: localPointer.dy - 36,
                child: IgnorePointer(
                  child: Image.asset(
                    GameAssets.rope,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
            if (_activeFlights.isNotEmpty)
              Positioned.fill(
                child: DollarFlightLayer(
                  flights: _activeFlights,
                  eventId: _lastFlightEventId,
                  boardKey: _boardKey,
                  scoreKey: _scoreKey,
                  rootKey: _rootKey,
                  cellSize: _cellSize,
                  onFinished: () {
                    if (mounted) {
                      setState(() => _activeFlights = []);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.piece,
    required this.slotSize,
    required this.cellSize,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.onTap,
    this.highlighted = false,
    this.dragging = false,
  });

  final TrayPiece? piece;
  final double slotSize;
  final double cellSize;
  final void Function(Offset global) onDragStart;
  final void Function(Offset global) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final p = piece;

    Widget child = Container(
      width: slotSize,
      height: slotSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted
            ? BoomColors.rope.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? BoomColors.rope : Colors.transparent,
          width: 2,
        ),
      ),
      child: p == null
          ? const SizedBox.shrink()
          : Opacity(
              opacity: dragging ? 0.2 : 1,
              child: PiecePreview(
                shape: p.shape,
                cellSize: cellSize,
                hasRope: p.hasRope,
              ),
            ),
    );

    if (p != null) {
      // Immediate pan-drag (no long-press). Tap still works for rope rotate
      // when the finger doesn't move past touch slop.
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: (d) => onDragStart(d.globalPosition),
        onPanUpdate: (d) => onDragUpdate(d.globalPosition),
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragCancel,
        child: child,
      );
    }

    return child;
  }
}
