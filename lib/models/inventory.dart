class ItemMeter {
  ItemMeter({
    this.count = 1,
    this.progress = 0,
    this.threshold = 50,
    this.tier = 0,
    this.maxCount = 2,
  });

  int count;
  int progress;
  int threshold;
  int tier;
  int maxCount;

  double get progressRatio =>
      threshold <= 0 ? 0 : (progress / threshold).clamp(0.0, 1.0);

  /// Returns true if a MAX popup should show.
  bool addScore(int points) {
    if (points <= 0) return false;
    var showMax = false;
    progress += points;
    while (progress >= threshold) {
      progress -= threshold;
      if (count < maxCount) {
        count++;
      } else {
        showMax = true;
      }
      tier++;
      threshold = nextThreshold(tier);
    }
    return showMax;
  }

  bool tryConsume() {
    if (count <= 0) return false;
    count--;
    return true;
  }

  static int nextThreshold(int tier) {
    // 50, 70, 95, 125, 160, ...
    var t = 50;
    for (var i = 0; i < tier; i++) {
      t += 20 + i * 5;
    }
    return t;
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'progress': progress,
        'threshold': threshold,
        'tier': tier,
        'maxCount': maxCount,
      };

  factory ItemMeter.fromJson(Map<String, dynamic> json) => ItemMeter(
        count: json['count'] as int? ?? 0,
        progress: json['progress'] as int? ?? 0,
        threshold: json['threshold'] as int? ?? 50,
        tier: json['tier'] as int? ?? 0,
        maxCount: json['maxCount'] as int? ?? 2,
      );

  ItemMeter copy() => ItemMeter(
        count: count,
        progress: progress,
        threshold: threshold,
        tier: tier,
        maxCount: maxCount,
      );
}

class Inventory {
  Inventory({
    ItemMeter? rope,
    ItemMeter? dynamite,
  })  : rope = rope ?? ItemMeter(count: 1, threshold: 50),
        dynamite = dynamite ??
            ItemMeter(count: 1, threshold: 65); // offset so meters desync

  final ItemMeter rope;
  final ItemMeter dynamite;

  Map<String, dynamic> toJson() => {
        'rope': rope.toJson(),
        'dynamite': dynamite.toJson(),
      };

  factory Inventory.fromJson(Map<String, dynamic> json) => Inventory(
        rope: ItemMeter.fromJson(
            Map<String, dynamic>.from(json['rope'] as Map? ?? {})),
        dynamite: ItemMeter.fromJson(
            Map<String, dynamic>.from(json['dynamite'] as Map? ?? {})),
      );
}
