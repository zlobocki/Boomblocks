import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How to Play', style: GoogleFonts.fredoka()),
        backgroundColor: BoomColors.skyTop,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BoomColors.skyTop, BoomColors.skyBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: const [
            _Section(
              title: 'Dig for treasure',
              body:
                  'Place earth blocks on the 8×8 board. Every piece of dirt '
                  'hides something — gems, fossils, or empty ground. Clear '
                  'full rows and columns to dig them up.',
            ),
            _Section(
              title: 'Clear lines, earn cash',
              body:
                  'A full row or column vanishes and pays out whatever was '
                  'buried in it. Fossils dig up for \$0 but still count as '
                  'finds.\n\n'
                  '• Silver \$5\n'
                  '• Gold \$10\n'
                  '• Emerald \$15\n'
                  '• Ruby \$25\n'
                  '• Diamond \$50',
            ),
            _Section(
              title: 'Fresh loot',
              body:
                  'After you\'ve collected 7 items (gems or fossils), the '
                  'underground resets with a new mix. Better gems unlock as '
                  'you dig deeper.',
            ),
            _Section(
              title: 'Three tools',
              body:
                  '• Rope — rotate a piece before you place it\n'
                  '• Dynamite — blast a piece off the board (and dig '
                  'whatever it was sitting on)\n'
                  '• Undo — take back your last placement\n\n'
                  'Each tool starts charged once and holds up to 2 uses. '
                  'Spending cash recharges them.',
            ),
            _Section(
              title: 'Every deal is solvable',
              body:
                  'The three pieces you\'re dealt can always be placed — '
                  'sometimes with a clever rotation or a well-timed blast. '
                  'If nothing fits and you\'re out of dynamite, the run is '
                  'over. Undo is your last chance when you\'re stuck.',
            ),
            _Section(
              title: 'Top 10',
              body:
                  'Your best digs are saved. Crack the leaderboard.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BoomColors.hud.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BoomColors.frameGold.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: BoomColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: BoomColors.cream.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
