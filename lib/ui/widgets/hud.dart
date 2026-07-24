import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.round,
    required this.difficulty,
    this.scoreToast,
    required this.onMenu,
  });

  final int score;
  final int round;
  final int difficulty;
  final String? scoreToast;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
            color: BoomColors.ink,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'BoomBlocks',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: BoomColors.ink,
                  ),
                ),
                AnimatedOpacity(
                  opacity: scoreToast != null ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    scoreToast ?? ' ',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BoomColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StatChip(label: 'Score', value: '$score'),
          const SizedBox(width: 8),
          _StatChip(label: 'Rnd', value: '$round'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BoomColors.hud.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BoomColors.earth.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BoomColors.ink.withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BoomColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
