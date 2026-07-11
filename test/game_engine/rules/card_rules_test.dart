import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:exploding_kittens/game_engine/rules/card_rules.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _stateWithHand(List<CardModel> hand) {
  return GameState(
    id: 'g1',
    config: const GameConfig(playerCount: 2),
    players: [
      PlayerModel(id: 'p1', name: 'A', hand: hand),
      const PlayerModel(id: 'p2', name: 'B', hand: []),
    ],
    deck: const DeckModel(drawPile: [], discardPile: []),
    turn: const TurnModel(currentPlayerId: 'p1', phase: TurnPhase.playing),
    phase: GamePhase.playing,
  );
}

void main() {
  group('CardRules.canPlay', () {
    test('una carta jugable normal (Skip) en mano y en turno es válida', () {
      const card = CardModel(id: 'a', type: CardType.skip);
      expect(CardRules.canPlay(card, _stateWithHand([card])), isTrue);
    });

    test(
      'una carta de gato sola nunca es jugable, aunque esté en mano y en '
      'turno — solo tiene efecto en pareja/trío',
      () {
        const card = CardModel(id: 'a', type: CardType.tacocat);
        expect(CardRules.canPlay(card, _stateWithHand([card])), isFalse);
      },
    );

    test('explodingKitten y defuse nunca son jugables sueltos', () {
      const bomb = CardModel(id: 'a', type: CardType.explodingKitten);
      const defuse = CardModel(id: 'b', type: CardType.defuse);
      expect(CardRules.canPlay(bomb, _stateWithHand([bomb])), isFalse);
      expect(CardRules.canPlay(defuse, _stateWithHand([defuse])), isFalse);
    });

    test('fuera de turno no es jugable', () {
      const card = CardModel(id: 'a', type: CardType.skip);
      final state = GameState(
        id: 'g1',
        config: const GameConfig(playerCount: 2),
        players: [
          const PlayerModel(id: 'p1', name: 'A', hand: [card]),
          const PlayerModel(id: 'p2', name: 'B', hand: []),
        ],
        deck: const DeckModel(drawPile: [], discardPile: []),
        turn: const TurnModel(currentPlayerId: 'p2', phase: TurnPhase.playing),
        phase: GamePhase.playing,
      );
      expect(CardRules.canPlay(card, state), isFalse);
    });
  });

  group('CardRules.isValidCatPair', () {
    test('dos gatos del mismo tipo es válido', () {
      const cards = [
        CardModel(id: 'a', type: CardType.tacocat),
        CardModel(id: 'b', type: CardType.tacocat),
      ];
      expect(CardRules.isValidCatPair(cards), isTrue);
    });

    test('dos gatos de distinto tipo no es válido', () {
      const cards = [
        CardModel(id: 'a', type: CardType.tacocat),
        CardModel(id: 'b', type: CardType.cattermelon),
      ];
      expect(CardRules.isValidCatPair(cards), isFalse);
    });

    test('una sola carta no es par', () {
      const cards = [CardModel(id: 'a', type: CardType.tacocat)];
      expect(CardRules.isValidCatPair(cards), isFalse);
    });

    test('carta no-gato no forma par', () {
      const cards = [
        CardModel(id: 'a', type: CardType.nope),
        CardModel(id: 'b', type: CardType.nope),
      ];
      expect(CardRules.isValidCatPair(cards), isFalse);
    });
  });

  group('CardRules.isValidCatTrio', () {
    test('tres gatos del mismo tipo es válido', () {
      const cards = [
        CardModel(id: 'a', type: CardType.cattermelon),
        CardModel(id: 'b', type: CardType.cattermelon),
        CardModel(id: 'c', type: CardType.cattermelon),
      ];
      expect(CardRules.isValidCatTrio(cards), isTrue);
    });

    test('solo dos no forma trío', () {
      const cards = [
        CardModel(id: 'a', type: CardType.cattermelon),
        CardModel(id: 'b', type: CardType.cattermelon),
      ];
      expect(CardRules.isValidCatTrio(cards), isFalse);
    });
  });
}
