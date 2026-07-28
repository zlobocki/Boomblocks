enum GemType {
  coal,
  silver,
  gold,
  emerald,
  ruby,
  diamond,
}

extension GemTypeX on GemType {
  int get value => switch (this) {
        GemType.coal => 0,
        GemType.silver => 5,
        GemType.gold => 10,
        GemType.emerald => 15,
        GemType.ruby => 25,
        GemType.diamond => 50,
      };

  String get label => switch (this) {
        GemType.coal => 'Coal',
        GemType.silver => 'Silver',
        GemType.gold => 'Gold',
        GemType.emerald => 'Emerald',
        GemType.ruby => 'Ruby',
        GemType.diamond => 'Diamond',
      };

  String get emoji => switch (this) {
        GemType.coal => '●',
        GemType.silver => '◇',
        GemType.gold => '◆',
        GemType.emerald => '◈',
        GemType.ruby => '♦',
        GemType.diamond => '✦',
      };
}
