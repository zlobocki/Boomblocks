import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/game_controller.dart';
import '../persistence/game_storage.dart';
import '../theme/app_theme.dart';
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
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _refresh();
  }

  Future<void> _refresh() async {
    final has = await _storage.hasSavedGame();
    if (mounted) setState(() => _hasSave = has);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5BB4D4),
              BoomColors.skyBottom,
              Color(0xFFE2B87A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _bob,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, (_bob.value - 0.5) * 10),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'BoomBlocks',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: BoomColors.ink,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fit the earth. Blast for gems.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BoomColors.ink.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Decorative gem row as visual anchor (not cards)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _GemDot(Color(0xFF3A3A3A)),
                    SizedBox(width: 10),
                    _GemDot(Color(0xFFC0C0C0)),
                    SizedBox(width: 10),
                    _GemDot(Color(0xFFFFD700)),
                    SizedBox(width: 10),
                    _GemDot(Color(0xFF2ECC71)),
                    SizedBox(width: 10),
                    _GemDot(Color(0xFFE74C3C)),
                    SizedBox(width: 10),
                    _GemDot(Color(0xFF7FDBFF)),
                  ],
                ),
                const Spacer(flex: 2),
                if (_hasSave) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _start(continueGame: true),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_hasSave) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('New game?'),
                            content: const Text(
                              'This will replace your saved run.',
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
                    style: _hasSave
                        ? ElevatedButton.styleFrom(
                            backgroundColor: BoomColors.earthDark,
                          )
                        : null,
                    child: Text(_hasSave ? 'New game' : 'Play'),
                  ),
                ),
                const SizedBox(height: 12),
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
                      fontSize: 16,
                      color: BoomColors.ink,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Phone portrait · tablet later',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: BoomColors.ink.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GemDot extends StatelessWidget {
  const _GemDot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
