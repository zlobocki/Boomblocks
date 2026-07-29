enum GemType {
  skull,
  bones,
  silver,
  gold,
  emerald,
  ruby,
  diamond,
}

extension GemTypeX on GemType {
  int get value => switch (this) {
        GemType.skull => 0,
        GemType.bones => 0,
        GemType.silver => 5,
        GemType.gold => 10,
        GemType.emerald => 15,
        GemType.ruby => 25,
        GemType.diamond => 50,
      };

  bool get isWorthless => value <= 0;

  String get label => switch (this) {
        GemType.skull => 'Skull',
        GemType.bones => 'Bones',
        GemType.silver => 'Silver',
        GemType.gold => 'Gold',
        GemType.emerald => 'Emerald',
        GemType.ruby => 'Ruby',
        GemType.diamond => 'Diamond',
      };

  String get assetName => name;
}
