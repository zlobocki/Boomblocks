class HighScoreEntry {
  HighScoreEntry({
    required this.name,
    required this.score,
    required this.dateIso,
  });

  final String name;
  final String dateIso;
  final int score;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'dateIso': dateIso,
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> json) => HighScoreEntry(
        name: json['name'] as String? ?? 'Player',
        score: json['score'] as int? ?? 0,
        dateIso: json['dateIso'] as String? ?? DateTime.now().toIso8601String(),
      );
}
