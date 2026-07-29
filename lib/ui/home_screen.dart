import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/game_controller.dart';
import '../persistence/game_storage.dart';
import '../theme/app_theme.dart';
import '../theme/game_assets.dart';
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            GameAssets.welcomeBg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Vignette + lantern warmth so CTAs read clearly
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
                        const Color(0x33000000),
                        const Color(0x22000000),
                        t,
                      )!,
                      Colors.transparent,
                      Color.lerp(
                        const Color(0xAA120A06),
                        const Color(0xBB1A0F08),
                        t,
                      )!,
                      const Color(0xEE0B0907),
                    ],
                    stops: const [0.0, 0.38, 0.68, 1.0],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  // Brand reinforcement above CTAs (bg already has title)
                  Text(
                    'DIG · CLEAR · CASH IN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: BoomColors.gold.withValues(alpha: 0.9),
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
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
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
                            controller: GameController(storage: _storage),
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
