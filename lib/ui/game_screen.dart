import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_controller.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';
import 'scoreboard_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/hud.dart';
import 'widgets/item_slot.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller, this.continuing = false});

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
  Offset? _dynamiteHover;
  bool _draggingRope = false;
  bool _draggingDynamite = false;
  bool _showRopeMax = false;
  bool _showDynMax = false;
  bool _gameOverShown = false;
  final GlobalKey _boardKey = GlobalKey();

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
      if (c.maxToast != null) {
        _showRopeMax = c.inventory.rope.count >= c.inventory.rope.maxCount;
        _showDynMax = c.inventory.dynamite.count >= c.inventory.dynamite.maxCount;
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

  Rect? _boardRect() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  void _updatePiecePreview(Offset global, TrayPiece piece, double cellSize) {
    final rect = _boardRect();
    if (rect == null) return;
    final local = global - rect.topLeft;
    // Anchor preview so piece center-ish follows finger
    final anchorCol = (local.dx / cellSize).floor() - (piece.shape.width ~/ 2);
    final anchorRow = (local.dy / cellSize).floor() - (piece.shape.height ~/ 2);
    final valid = BoardLogic.canPlace(c.board, piece.shape, anchorRow, anchorCol);
    setState(() {
      _previewShape = piece.shape;
      _previewRow = anchorRow;
      _previewCol = anchorCol;
      _previewValid = valid;
    });
  }

  void _clearPreview() {
    setState(() {
      _previewShape = null;
      _previewRow = null;
      _previewCol = null;
      _previewValid = false;
      _dynamiteHover = null;
      _draggingRope = false;
      _draggingDynamite = false;
    });
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Game Over',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Score: ${c.score}',
                style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800),
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
                if (qualifies) {
                  await c.submitHighScore(nameCtrl.text);
                }
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
                if (qualifies) {
                  await c.submitHighScore(nameCtrl.text);
                }
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
                  MaterialPageRoute(builder: (_) => ScoreboardScreen(controller: c)),
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
    final cellSize = boardSide / BoardLogic.size;
    final trayCell = cellSize * 0.72;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BoomColors.skyTop, BoomColors.skyBottom, Color(0xFFE8C9A0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              GameHud(
                score: c.score,
                round: c.round,
                difficulty: c.difficultyLevel,
                scoreToast: c.lastScoreToast,
                onMenu: _openMenu,
              ),
              const SizedBox(height: 4),
              DragTarget<String>(
                onWillAcceptWithDetails: (details) {
                  return details.data.startsWith('piece:') ||
                      details.data == 'dynamite';
                },
                onMove: (details) {
                  final rect = _boardRect();
                  if (rect == null) return;
                  if (details.data == 'dynamite') {
                    setState(() {
                      _dynamiteHover = details.offset - rect.topLeft +
                          const Offset(28, 28);
                    });
                    return;
                  }
                  if (details.data.startsWith('piece:')) {
                    final idx = int.parse(details.data.split(':')[1]);
                    final piece = c.tray[idx];
                    if (piece == null) return;
                    _updatePiecePreview(
                      details.offset + Offset(trayCell, trayCell),
                      piece,
                      cellSize,
                    );
                  }
                },
                onLeave: (_) => _clearPreview(),
                onAcceptWithDetails: (details) {
                  final rect = _boardRect();
                  if (rect == null) {
                    _clearPreview();
                    return;
                  }
                  if (details.data == 'dynamite') {
                    final local = details.offset - rect.topLeft + const Offset(28, 28);
                    final col = (local.dx / cellSize).floor().clamp(0, 7);
                    final row = (local.dy / cellSize).floor().clamp(0, 7);
                    c.useDynamite(row, col);
                    _clearPreview();
                    return;
                  }
                  if (details.data.startsWith('piece:')) {
                    final idx = int.parse(details.data.split(':')[1]);
                    final piece = c.tray[idx];
                    if (piece != null &&
                        _previewRow != null &&
                        _previewCol != null &&
                        _previewValid) {
                      c.placePiece(idx, _previewRow!, _previewCol!);
                    }
                  }
                  _clearPreview();
                },
                builder: (context, candidate, rejected) {
                  return KeyedSubtree(
                    key: _boardKey,
                    child: BoardWidget(
                      board: c.board,
                      cellSize: cellSize,
                      previewShape: _previewShape,
                      previewRow: _previewRow,
                      previewCol: _previewCol,
                      previewValid: _previewValid,
                      dynamiteHover: _draggingDynamite ? _dynamiteHover : null,
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: BoomColors.tray.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: BoomColors.earth.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) {
                      final piece = c.tray[i];
                      return _TraySlot(
                        piece: piece,
                        cellSize: trayCell,
                        highlighted: _draggingRope,
                        onTap: piece != null && piece.hasRope
                            ? () => c.rotatePiece(i)
                            : null,
                        dragData: 'piece:$i',
                        onDragStarted: () {},
                        onDragEnded: _clearPreview,
                        ropeTarget: _draggingRope,
                        onAcceptRope: () {
                          c.applyRopeToPiece(i);
                          setState(() => _draggingRope = false);
                        },
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ItemSlot(
                      label: 'Rope',
                      icon: Icons.rotate_right_rounded,
                      meter: c.inventory.rope,
                      accent: BoomColors.rope,
                      showMax: _showRopeMax,
                      onDragStarted: () => setState(() => _draggingRope = true),
                      onDragEnded: () => setState(() => _draggingRope = false),
                    ),
                    const SizedBox(width: 36),
                    ItemSlot(
                      label: 'Dynamite',
                      icon: Icons.local_fire_department_rounded,
                      meter: c.inventory.dynamite,
                      accent: BoomColors.dynamite,
                      showMax: _showDynMax,
                      onDragStarted: () => setState(() => _draggingDynamite = true),
                      onDragEnded: () {
                        setState(() {
                          _draggingDynamite = false;
                          _dynamiteHover = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.piece,
    required this.cellSize,
    required this.dragData,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.ropeTarget,
    required this.onAcceptRope,
    this.onTap,
    this.highlighted = false,
  });

  final TrayPiece? piece;
  final double cellSize;
  final String dragData;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final bool ropeTarget;
  final VoidCallback onAcceptRope;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: cellSize * 4.2,
      height: cellSize * 4.2,
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
      child: piece == null
          ? const SizedBox.shrink()
          : GestureDetector(
              onTap: onTap,
              child: PiecePreview(
                shape: piece!.shape,
                cellSize: cellSize,
                hasRope: piece!.hasRope,
              ),
            ),
    );

    if (piece != null) {
      child = LongPressDraggable<String>(
        data: dragData,
        delay: const Duration(milliseconds: 120),
        onDragStarted: onDragStarted,
        onDragEnd: (_) => onDragEnded(),
        feedback: Material(
          color: Colors.transparent,
          child: PiecePreview(
            shape: piece!.shape,
            cellSize: cellSize,
            hasRope: piece!.hasRope,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: child),
        child: child,
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data == 'rope' && piece != null && !piece!.hasRope,
      onAcceptWithDetails: (_) => onAcceptRope(),
      builder: (context, cand, rej) => child,
    );
  }
}
