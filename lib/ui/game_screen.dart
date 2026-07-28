import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_controller.dart';
import '../../models/piece.dart';
import '../../systems/board_logic.dart';
import '../../theme/app_theme.dart';
import '../../theme/game_assets.dart';
import 'scoreboard_screen.dart';
import 'widgets/board_widget.dart';
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
  bool _showRopeMax = false;
  bool _showDynMax = false;
  bool _gameOverShown = false;

  int? _dragTrayIndex;
  Offset? _dragPointerGlobal;
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

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

  RenderBox? _boardBox() {
    return _boardKey.currentContext?.findRenderObject() as RenderBox?;
  }

  void _updatePieceSnapFromPointer(
    Offset global,
    TrayPiece piece,
    double cellSize,
  ) {
    final box = _boardBox();
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(global);
    final lift = cellSize * (piece.shape.height + 0.55);
    final anchorX = local.dx - (piece.shape.width * cellSize) / 2;
    final anchorY = local.dy - lift;

    var originCol = (anchorX / cellSize).round();
    var originRow = (anchorY / cellSize).round();
    originCol = originCol.clamp(0, BoardLogic.size - piece.shape.width);
    originRow = originRow.clamp(0, BoardLogic.size - piece.shape.height);

    final pad = cellSize * 2;
    final outside = local.dx < -pad ||
        local.dy < -pad ||
        local.dx > box.size.width + pad ||
        local.dy > box.size.height + pad;

    if (outside) {
      setState(() {
        _previewShape = null;
        _previewRow = null;
        _previewCol = null;
        _previewValid = false;
        _dragPointerGlobal = global;
      });
      return;
    }

    final valid =
        BoardLogic.canPlace(c.board, piece.shape, originRow, originCol);
    setState(() {
      _previewShape = piece.shape;
      _previewRow = originRow;
      _previewCol = originCol;
      _previewValid = valid;
      _dragPointerGlobal = global;
    });
  }

  void _updateDynamiteFromPointer(Offset global, double cellSize) {
    final box = _boardBox();
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > box.size.width ||
        local.dy > box.size.height) {
      setState(() {
        _dynamiteRow = null;
        _dynamiteCol = null;
        _dragPointerGlobal = global;
      });
      return;
    }
    setState(() {
      _dynamiteCol =
          (local.dx / cellSize).floor().clamp(0, BoardLogic.size - 1);
      _dynamiteRow =
          (local.dy / cellSize).floor().clamp(0, BoardLogic.size - 1);
      _dragPointerGlobal = global;
    });
  }

  void _finishDrag() {
    if (_dragTrayIndex != null) {
      final idx = _dragTrayIndex!;
      if (_previewValid && _previewRow != null && _previewCol != null) {
        c.placePiece(idx, _previewRow!, _previewCol!);
      }
    } else if (_draggingDynamite) {
      if (_dynamiteRow != null && _dynamiteCol != null) {
        c.useDynamite(_dynamiteRow!, _dynamiteCol!);
      }
    }
    _clearPreview();
  }

  void _clearPreview() {
    setState(() {
      _previewShape = null;
      _previewRow = null;
      _previewCol = null;
      _previewValid = false;
      _dynamiteRow = null;
      _dynamiteCol = null;
      _draggingRope = false;
      _draggingDynamite = false;
      _dragTrayIndex = null;
      _dragPointerGlobal = null;
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
                'Score: ${c.score}',
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

  Offset? _localPointer() {
    final global = _dragPointerGlobal;
    if (global == null) return null;
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
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
    final localPointer = _localPointer();
    final draggingPiece =
        _dragTrayIndex != null ? c.tray[_dragTrayIndex!] : null;

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) {
          if (_dragTrayIndex != null) {
            final piece = c.tray[_dragTrayIndex!];
            if (piece != null) {
              _updatePieceSnapFromPointer(e.position, piece, cellSize);
            }
          } else if (_draggingDynamite) {
            _updateDynamiteFromPointer(e.position, cellSize);
          }
        },
        onPointerUp: (_) => _finishDrag(),
        onPointerCancel: (_) => _clearPreview(),
        child: Container(
          key: _stackKey,
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
                      difficulty: c.difficultyLevel,
                      scoreToast: c.lastScoreToast,
                      onMenu: _openMenu,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: KeyedSubtree(
                          key: _boardKey,
                          child: BoardWidget(
                            board: c.board,
                            cellSize: cellSize,
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
                            final slotW =
                                (constraints.maxWidth - gap * 2) / 3;
                            const maxCells = 4;
                            final pieceCell = ((slotW - 8) / maxCells)
                                .clamp(12.0, cellSize * 0.7);
                            return Row(
                              children: List.generate(3, (i) {
                                final piece = c.tray[i];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: i == 0 ? 0 : gap,
                                  ),
                                  child: SizedBox(
                                    width: slotW,
                                    child: _TraySlot(
                                      piece: piece,
                                      slotSize: slotW,
                                      cellSize: pieceCell,
                                      highlighted: _draggingRope,
                                      dragging: _dragTrayIndex == i,
                                      onTap: piece != null && piece.hasRope
                                          ? () => c.rotatePiece(i)
                                          : null,
                                      onDragStart: (global) {
                                        setState(() {
                                          _dragTrayIndex = i;
                                          _dragPointerGlobal = global;
                                        });
                                        if (piece != null) {
                                          _updatePieceSnapFromPointer(
                                            global,
                                            piece,
                                            cellSize,
                                          );
                                        }
                                      },
                                      onDragUpdate: (global) {
                                        if (piece == null) return;
                                        _updatePieceSnapFromPointer(
                                          global,
                                          piece,
                                          cellSize,
                                        );
                                      },
                                      onAcceptRope: () {
                                        c.applyRopeToPiece(i);
                                        setState(
                                            () => _draggingRope = false);
                                      },
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
                            onDragStarted: () =>
                                setState(() => _draggingRope = true),
                            onDragEnded: () =>
                                setState(() => _draggingRope = false),
                          ),
                          const SizedBox(width: 28),
                          ItemSlot(
                            label: 'Dynamite',
                            assetPath: GameAssets.dynamite,
                            meter: c.inventory.dynamite,
                            accent: BoomColors.dynamite,
                            showMax: _showDynMax,
                            onDragStarted: () =>
                                setState(() => _draggingDynamite = true),
                            onDragEnded: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (draggingPiece != null && localPointer != null)
                Positioned(
                  left: localPointer.dx -
                      (draggingPiece.shape.width * cellSize) / 2,
                  top: localPointer.dy -
                      cellSize * (draggingPiece.shape.height + 0.55),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.95,
                      child: PiecePreview(
                        shape: draggingPiece.shape,
                        cellSize: cellSize,
                        hasRope: draggingPiece.hasRope,
                      ),
                    ),
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
    required this.slotSize,
    required this.cellSize,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onAcceptRope,
    this.onTap,
    this.highlighted = false,
    this.dragging = false,
  });

  final TrayPiece? piece;
  final double slotSize;
  final double cellSize;
  final void Function(Offset global) onDragStart;
  final void Function(Offset global) onDragUpdate;
  final VoidCallback onAcceptRope;
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
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (d) => onDragStart(d.globalPosition),
        onLongPressMoveUpdate: (d) => onDragUpdate(d.globalPosition),
        child: child,
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) =>
          d.data == 'rope' && p != null && !p.hasRope,
      onAcceptWithDetails: (_) => onAcceptRope(),
      builder: (context, cand, rej) => child,
    );
  }
}
