import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_result.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('toJson / fromJson round-trip conserva un estado mínimo', () {
      const state = GameState(
        id: 'g1',
        config: GameConfig(playerCount: 2),
        players: [
          PlayerModel(id: 'p1', name: 'Alice', hand: []),
          PlayerModel(id: 'p2', name: 'Bob', hand: []),
        ],
        deck: DeckModel(drawPile: [], discardPile: []),
        turn: TurnModel(currentPlayerId: 'p1', phase: TurnPhase.playing),
        phase: GamePhase.playing,
      );

      final restored = GameState.fromJson(state.toJson());
      expect(restored, equals(state));
    });

    test(
      'toJson / fromJson conserva pendingAction, pendingBomb, '
      'seeTheFutureCards y result',
      () {
        const state = GameState(
          id: 'g1',
          config: GameConfig(playerCount: 2),
          players: [PlayerModel(id: 'p1', name: 'Alice', hand: [])],
          deck: DeckModel(drawPile: [], discardPile: []),
          turn: TurnModel(
            currentPlayerId: 'p1',
            phase: TurnPhase.nopeWindow,
          ),
          phase: GamePhase.finished,
          pendingAction: PlayFavorAction(
            playerId: 'p1',
            card: CardModel(id: 'favor_1', type: CardType.favor),
            targetPlayerId: 'p2',
          ),
          pendingBomb: CardModel(id: 'bomb_1', type: CardType.explodingKitten),
          seeTheFutureCards: [
            CardModel(id: 'a', type: CardType.attack),
            CardModel(id: 'b', type: CardType.skip),
          ],
          result: GameResult(
            winnerId: 'p1',
            winnerName: 'Alice',
            totalTurns: 5,
            eliminationOrder: ['p2'],
          ),
          turnCount: 5,
          eliminationOrder: ['p2'],
        );

        final restored = GameState.fromJson(state.toJson());
        expect(restored, equals(state));
        expect(restored.pendingAction, isA<PlayFavorAction>());
        expect(restored.result!.winnerName, 'Alice');
      },
    );
  });
}
