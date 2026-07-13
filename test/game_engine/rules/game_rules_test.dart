import 'package:exploding_kittens/core/errors/exceptions.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:exploding_kittens/game_engine/rules/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _state({
  required List<PlayerModel> players,
  TurnPhase phase = TurnPhase.playing,
  CardModel? pendingBomb,
  Object? pendingAction,
  String currentPlayerId = 'p1',
}) {
  return GameState(
    id: 'g1',
    config: const GameConfig(playerCount: 2),
    players: players,
    deck: const DeckModel(drawPile: [], discardPile: []),
    turn: TurnModel(currentPlayerId: currentPlayerId, phase: phase),
    phase: GamePhase.playing,
    pendingBomb: pendingBomb,
    pendingAction: pendingAction,
  );
}

void main() {
  group('GameRules.validate — fase del turno', () {
    test('DrawCardAction es válido en TurnPhase.playing', () {
      final state = _state(
        players: const [
          PlayerModel(id: 'p1', name: 'A', hand: []),
          PlayerModel(id: 'p2', name: 'B', hand: []),
        ],
      );
      expect(
        () => GameRules.validate(
          const DrawCardAction(playerId: 'p1'),
          state,
        ),
        returnsNormally,
      );
    });

    test(
      'DrawCardAction se rechaza durante una ventana de Nope abierta — '
      'no debe poder "colarse" y perder la acción pendiente',
      () {
        final state = _state(
          players: const [
            PlayerModel(id: 'p1', name: 'A', hand: []),
            PlayerModel(id: 'p2', name: 'B', hand: []),
          ],
          phase: TurnPhase.nopeWindow,
        );
        expect(
          () => GameRules.validate(
            const DrawCardAction(playerId: 'p1'),
            state,
          ),
          throwsA(isA<InvalidActionException>()),
        );
      },
    );

    test('DrawCardAction se rechaza mientras se resuelve una bomba', () {
      const bomb = CardModel(id: 'bomb-1', type: CardType.explodingKitten);
      final state = _state(
        players: const [
          PlayerModel(id: 'p1', name: 'A', hand: []),
          PlayerModel(id: 'p2', name: 'B', hand: []),
        ],
        phase: TurnPhase.resolving,
        pendingBomb: bomb,
      );
      expect(
        () => GameRules.validate(
          const DrawCardAction(playerId: 'p1'),
          state,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('PlayCatPairAction se rechaza si ya hay una ventana de Nope abierta',
        () {
      const cat1 = CardModel(id: 'a', type: CardType.tacocat);
      const cat2 = CardModel(id: 'b', type: CardType.tacocat);
      final state = _state(
        players: [
          PlayerModel(id: 'p1', name: 'A', hand: const [cat1, cat2]),
          const PlayerModel(id: 'p2', name: 'B', hand: []),
        ],
        phase: TurnPhase.nopeWindow,
      );
      expect(
        () => GameRules.validate(
          const PlayCatPairAction(
            playerId: 'p1',
            cards: [cat1, cat2],
            targetPlayerId: 'p2',
          ),
          state,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test(
      'DefuseBombAction es válido en TurnPhase.resolving con una bomba '
      'pendiente',
      () {
        const bomb = CardModel(id: 'bomb-1', type: CardType.explodingKitten);
        const defuse = CardModel(id: 'defuse-1', type: CardType.defuse);
        final state = _state(
          players: [
            PlayerModel(id: 'p1', name: 'A', hand: const [defuse]),
            const PlayerModel(id: 'p2', name: 'B', hand: []),
          ],
          phase: TurnPhase.resolving,
          pendingBomb: bomb,
        );
        expect(
          () => GameRules.validate(
            const DefuseBombAction(
              playerId: 'p1',
              defuseCard: defuse,
              insertAtPosition: 0,
            ),
            state,
          ),
          returnsNormally,
        );
      },
    );

    test('DefuseBombAction se rechaza si no hay ninguna bomba pendiente', () {
      const defuse = CardModel(id: 'defuse-1', type: CardType.defuse);
      final state = _state(
        players: [
          PlayerModel(id: 'p1', name: 'A', hand: const [defuse]),
          const PlayerModel(id: 'p2', name: 'B', hand: []),
        ],
        phase: TurnPhase.playing,
      );
      expect(
        () => GameRules.validate(
          const DefuseBombAction(
            playerId: 'p1',
            defuseCard: defuse,
            insertAtPosition: 0,
          ),
          state,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });
  });

  group('GameRules.validate — ChooseCardAction (respuesta de Favor)', () {
    const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
    const givenCard = CardModel(id: 'given-1', type: CardType.skip);

    GameState awaitingChoiceState() => _state(
          players: [
            const PlayerModel(id: 'p1', name: 'A', hand: []),
            PlayerModel(id: 'p2', name: 'B', hand: const [givenCard]),
          ],
          phase: TurnPhase.awaitingCardChoice,
          pendingAction: const PlayFavorAction(
            playerId: 'p1',
            card: favorCard,
            targetPlayerId: 'p2',
          ),
        );

    test(
        'es válido si lo elige el objetivo del Favor pendiente y tiene la '
        'carta', () {
      expect(
        () => GameRules.validate(
          const ChooseCardAction(playerId: 'p2', cardId: 'given-1'),
          awaitingChoiceState(),
        ),
        returnsNormally,
      );
    });

    test('se rechaza si lo intenta elegir alguien que no es el objetivo', () {
      expect(
        () => GameRules.validate(
          const ChooseCardAction(playerId: 'p1', cardId: 'given-1'),
          awaitingChoiceState(),
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('se rechaza si la carta no está en la mano del objetivo', () {
      expect(
        () => GameRules.validate(
          const ChooseCardAction(playerId: 'p2', cardId: 'no-existe'),
          awaitingChoiceState(),
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('se rechaza fuera de TurnPhase.awaitingCardChoice', () {
      final state = _state(
        players: [
          const PlayerModel(id: 'p1', name: 'A', hand: []),
          PlayerModel(id: 'p2', name: 'B', hand: const [givenCard]),
        ],
        phase: TurnPhase.playing,
        pendingAction: const PlayFavorAction(
          playerId: 'p1',
          card: favorCard,
          targetPlayerId: 'p2',
        ),
      );
      expect(
        () => GameRules.validate(
          const ChooseCardAction(playerId: 'p2', cardId: 'given-1'),
          state,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('se rechaza si no hay ninguna elección pendiente', () {
      final state = _state(
        players: [
          const PlayerModel(id: 'p1', name: 'A', hand: []),
          PlayerModel(id: 'p2', name: 'B', hand: const [givenCard]),
        ],
        phase: TurnPhase.awaitingCardChoice,
      );
      expect(
        () => GameRules.validate(
          const ChooseCardAction(playerId: 'p2', cardId: 'given-1'),
          state,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });
  });
}
