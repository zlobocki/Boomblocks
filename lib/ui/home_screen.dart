import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/game_controller.dart';
import '../persistence/game_storage.dart';
import '../systems/music_service.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/game_assets.dart';
import '../theme/responsive.dart';
import 'game_screen.dart';
import 'scoreboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _storage = GameStorage();
  bool _hasSave = false;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    MusicService.instance.start();
    _refresh();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final has = await _storage.hasSavedGame();
    if (mounted) setState(() => _hasSave = has);
  }

  Future<void> _start({required bool continueGame}) async {
    final controller = GameController(storage: _storage);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          controller: controller,
          continuing: continueGame,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    final tablet = BoomLayout.isTablet(size);
    final sidePad = shortest < 360
        ? 20.0
        : (shortest < 400 ? 16.0 : (tablet ? 48.0 : 12.0));
    final titleSize = tablet
        ? (shortest * 0.09).clamp(48.0, 76.0)
        : (shortest * 0.12).clamp(34.0, 52.0);
    final actionsMax = BoomLayout.homeActionsMaxWidth(size);

    return Scaffold(
      backgroundColor: BoomColors.skyBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              GameAssets.welcomeBg,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.05),
            ),
          ),
          // Soft side vignette so edge tools don't fight the CTAs on narrow phones.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      BoomColors.skyBottom.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      BoomColors.skyBottom.withValues(alpha: 0.55),
                    ],
                    stops: shortest < 380
                        ? const [0.0, 0.12, 0.88, 1.0]
                        : const [0.0, 0.06, 0.94, 1.0],
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final t = _glow.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        const Color(0x99000000),
                        const Color(0x77000000),
                        t,
                      )!,
                      Colors.transparent,
                      Color.lerp(
                        const Color(0x99120A06),
                        const Color(0xBB1A0F08),
                        t,
                      )!,
                      const Color(0xF00B0907),
                    ],
                    stops: const [0.0, 0.32, 0.62, 1.0],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad + 8),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.appName,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.fredoka(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: BoomColors.gold,
                        height: 1,
                        shadows: const [
                          Shadow(
                            color: Color(0xCC000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                          Shadow(
                            color: Color(0x88000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 5),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: actionsMax),
                    child: Column(
                      children: [
                        Text(
                          AppStrings.tagline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: tablet ? 18 : 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: BoomColors.cream.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(
                                color: Color(0xAA000000),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_hasSave) ...[
                          _MineButton(
                            label: 'Continue',
                            filled: true,
                            onPressed: () => _start(continueGame: true),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MineButton(
                          label: _hasSave ? 'New game' : 'Play',
                          filled: !_hasSave,
                          onPressed: () async {
                            if (_hasSave) {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: BoomColors.hud,
                                  title: Text(
                                    'New game?',
                                    style: GoogleFonts.fredoka(
                                      color: BoomColors.gold,
                                    ),
                                  ),
                                  content: Text(
                                    'This will replace your saved run.',
                                    style: GoogleFonts.nunito(
                                      color: BoomColors.cream,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('New game'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              await _storage.clearGame();
                            }
                            if (!mounted) return;
                            _start(continueGame: false);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScoreboardScreen(
                                  controller:
                                      GameController(storage: _storage),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Top 10',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: BoomColors.cream,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MineButton extends StatelessWidget {
  const _MineButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE07A3D), Color(0xFFC45C26)],
                )
              : null,
          color: filled ? null : const Color(0xCC1A140F),
          border: Border.all(
            color: BoomColors.frameGold.withValues(alpha: filled ? 0.85 : 0.55),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BoomColors.cream,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
