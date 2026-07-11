import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameConfig', () {
    test('toJson / fromJson round-trip conserva todos los campos', () {
      const config = GameConfig(
        playerCount: 4,
        includeExpansion: true,
        botCount: 1,
        seed: 42,
      );

      final restored = GameConfig.fromJson(config.toJson());
      expect(restored, equals(config));
    });

    test('fromJson maneja seed nulo', () {
      const config = GameConfig(playerCount: 2);
      final restored = GameConfig.fromJson(config.toJson());
      expect(restored, equals(config));
      expect(restored.seed, isNull);
    });
  });
}
