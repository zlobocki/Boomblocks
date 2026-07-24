import 'gem.dart';

class BoardCell {
  BoardCell({
    this.filled = false,
    this.gem,
    this.gemRoundsLeft = 0,
  });

  bool filled;
  GemType? gem;
  int gemRoundsLeft;

  bool get hasGem => filled && gem != null;

  BoardCell copy() => BoardCell(
        filled: filled,
        gem: gem,
        gemRoundsLeft: gemRoundsLeft,
      );

  Map<String, dynamic> toJson() => {
        'filled': filled,
        'gem': gem?.name,
        'gemRoundsLeft': gemRoundsLeft,
      };

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    final gemName = json['gem'] as String?;
    return BoardCell(
      filled: json['filled'] as bool? ?? false,
      gem: gemName == null
          ? null
          : GemType.values.firstWhere(
              (g) => g.name == gemName,
              orElse: () => GemType.coal,
            ),
      gemRoundsLeft: json['gemRoundsLeft'] as int? ?? 0,
    );
  }

  void clear({bool keepEmpty = true}) {
    filled = false;
    gem = null;
    gemRoundsLeft = 0;
  }

  void placeEarth() {
    filled = true;
    gem = null;
    gemRoundsLeft = 0;
  }

  void setGem(GemType type, {int rounds = 2}) {
    if (!filled) return;
    gem = type;
    gemRoundsLeft = rounds;
  }
}
