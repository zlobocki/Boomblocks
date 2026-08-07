import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/game_assets.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.round,
    required this.lootProgress,
    required this.lootGoal,
    this.scoreToast,
    required this.onMenu,
    this.scoreKey,
  });

  final int score;
  final int round;
  final int lootProgress;
  final int lootGoal;
  final String? scoreToast;
  final VoidCallback onMenu;
  final GlobalKey? scoreKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
            color: BoomColors.cream,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  AppStrings.appName,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BoomColors.gold,
                    height: 1.1,
                  ),
                ),
                AnimatedOpacity(
                  opacity: scoreToast != null ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    scoreToast ?? ' ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BoomColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          KeyedSubtree(
            key: scoreKey,
            child: _StatChip(
              label: 'Cash',
              value: '\$$score',
              iconAsset: GameAssets.cashIcon,
            ),
          ),
          const SizedBox(width: 6),
          _StatChip(label: 'Loot', value: '$lootProgress/$lootGoal'),
          const SizedBox(width: 6),
          _StatChip(label: 'Rnd', value: '$round'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.iconAsset,
  });
  final String label;
  final String value;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: BoomColors.hud.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BoomColors.frameGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconAsset != null) ...[
                Image.asset(iconAsset!, width: 14, height: 14),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: BoomColors.dust.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BoomColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}
