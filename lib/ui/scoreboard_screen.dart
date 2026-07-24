import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/game_controller.dart';
import '../models/high_score.dart';
import '../theme/app_theme.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top 10', style: GoogleFonts.fredoka()),
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
        child: FutureBuilder<List<HighScoreEntry>>(
          future: controller.loadScores(),
          builder: (context, snap) {
            final scores = snap.data ?? [];
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (scores.isEmpty) {
              return Center(
                child: Text(
                  'No scores yet — go dig!',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: scores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = scores[i];
                final date = DateTime.tryParse(e.dateIso);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: BoomColors.hud.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: i == 0
                            ? BoomColors.rope
                            : BoomColors.earth,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (date != null)
                              Text(
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: BoomColors.ink.withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.score}',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: BoomColors.accentDeep,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
