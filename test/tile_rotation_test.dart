import 'package:boomblocks/controllers/game_controller.dart';
import 'package:boomblocks/persistence/game_storage.dart';
import 'package:boomblocks/theme/tile_texture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tile changes on every loot reset, no repeat within 10 resets', () {
    final c = GameController(storage: GameStorage());
    c.newGame();

    final picks = <int>[c.tileIndex];
    for (var i = 0; i < 60; i++) {
      c.debugRotateTile();
      picks.add(c.tileIndex);
    }

    for (var i = 1; i < picks.length; i++) {
      final start = i - GameController.tileHistoryWindow < 0
          ? 0
          : i - GameController.tileHistoryWindow;
      final recent = picks.sublist(start, i);
      expect(
        recent.contains(picks[i]),
        isFalse,
        reason: 'pick #$i (${picks[i]}) repeats one of the last '
            '${GameController.tileHistoryWindow}: $recent',
      );
      expect(picks[i], inInclusiveRange(1, TileTexture.count));
    }
  });

  test('tile history caps at the window size', () {
    final c = GameController(storage: GameStorage());
    c.newGame();
    for (var i = 0; i < 30; i++) {
      c.debugRotateTile();
    }
    expect(c.tileHistory.length, GameController.tileHistoryWindow);
  });

  test('tile index and history survive save/load', () async {
    final storage = GameStorage();
    final c = GameController(storage: storage);
    c.newGame();
    // Let newGame's fire-and-forget persist land before saving explicitly.
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 5; i++) {
      c.debugRotateTile();
    }
    final savedTile = c.tileIndex;
    final savedHistory = List<int>.of(c.tileHistory);
    await storage.saveGame(c.toJson());

    final restored = GameController(storage: storage);
    await restored.init();
    expect(restored.tileIndex, savedTile);
    expect(restored.tileHistory, savedHistory);
    expect(TileTexture.currentIndex, savedTile);
  });
}
