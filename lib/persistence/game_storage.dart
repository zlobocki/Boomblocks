import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/high_score.dart';

class GameStorage {
  static const _gameKey = 'boomblocks_active_game';
  static const _scoresKey = 'boomblocks_top_scores';

  Future<void> saveGame(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameKey, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameKey);
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> clearGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameKey);
  }

  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_gameKey);
  }

  Future<List<HighScoreEntry>> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoresKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => HighScoreEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  Future<bool> qualifiesForTop10(int score) async {
    if (score <= 0) return false;
    final scores = await loadScores();
    if (scores.length < 10) return true;
    return score > scores.last.score;
  }

  Future<List<HighScoreEntry>> submitScore(HighScoreEntry entry) async {
    final scores = await loadScores();
    scores.add(entry);
    scores.sort((a, b) => b.score.compareTo(a.score));
    final top = scores.take(10).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scoresKey,
      jsonEncode(top.map((e) => e.toJson()).toList()),
    );
    return top;
  }
}
