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

class _HomeScreenState extends State<HomeScreen> {
  final _storage = GameStorage();
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _refresh();
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
          // Full-bleed branded cave art
          Image.asset(
            GameAssets.welcomeBg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Soft bottom scrim so CTAs stay readable
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x99000000),
                  Color(0xCC1A0F08),
                ],
                stops: [0.0, 0.45, 0.72, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(),
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
                      style: _hasSave
                          ? ElevatedButton.styleFrom(
                              backgroundColor: BoomColors.earth,
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
