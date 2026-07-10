import 'package:exploding_kittens/game_engine/models/game/game_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameResult', () {
    test('toJson / fromJson round-trip conserva todos los campos', () {
      const result = GameResult(
        winnerId: 'p1',
        winnerName: 'Alice',
        totalTurns: 12,
        eliminationOrder: ['p3', 'p2'],
      );

      final restored = GameResult.fromJson(result.toJson());
      expect(restored, equals(result));
      // props omite winnerName (== quirk existente) — se comprueba aparte.
      expect(restored.winnerName, 'Alice');
    });
  });
}
