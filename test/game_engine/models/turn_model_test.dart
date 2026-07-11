import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnModel', () {
    test('toJson / fromJson round-trip conserva todos los campos', () {
      const turn = TurnModel(
        currentPlayerId: 'p1',
        phase: TurnPhase.nopeWindow,
        actionsLeft: 2,
        nopeChainCount: 3,
      );

      final restored = TurnModel.fromJson(turn.toJson());
      expect(restored, equals(turn));
    });

    test('fromJson conserva cada valor de TurnPhase', () {
      for (final phase in TurnPhase.values) {
        final turn = TurnModel(currentPlayerId: 'p1', phase: phase);
        final restored = TurnModel.fromJson(turn.toJson());
        expect(restored.phase, phase);
      }
    });
  });
}
