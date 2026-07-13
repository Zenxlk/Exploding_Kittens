import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnAction', () {
    test('DrawCardAction round-trip', () {
      const action = DrawCardAction(playerId: 'p1');
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<DrawCardAction>());
      expect((restored as DrawCardAction).playerId, 'p1');
    });

    test('PlayCardAction round-trip', () {
      const action = PlayCardAction(
        playerId: 'p1',
        card: CardModel(id: 'skip_1', type: CardType.skip),
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<PlayCardAction>());
      expect((restored as PlayCardAction).card, action.card);
    });

    test('PlayFavorAction round-trip', () {
      const action = PlayFavorAction(
        playerId: 'p1',
        card: CardModel(id: 'favor_1', type: CardType.favor),
        targetPlayerId: 'p2',
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<PlayFavorAction>());
      final r = restored as PlayFavorAction;
      expect(r.card, action.card);
      expect(r.targetPlayerId, 'p2');
    });

    test('PlayCatPairAction round-trip', () {
      const action = PlayCatPairAction(
        playerId: 'p1',
        cards: [
          CardModel(id: 'tacocat_1', type: CardType.tacocat),
          CardModel(id: 'tacocat_2', type: CardType.tacocat),
        ],
        targetPlayerId: 'p2',
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<PlayCatPairAction>());
      final r = restored as PlayCatPairAction;
      expect(r.cards, action.cards);
      expect(r.targetPlayerId, 'p2');
    });

    test('PlayCatTrioAction round-trip', () {
      const action = PlayCatTrioAction(
        playerId: 'p1',
        cards: [
          CardModel(id: 'tacocat_1', type: CardType.tacocat),
          CardModel(id: 'tacocat_2', type: CardType.tacocat),
          CardModel(id: 'tacocat_3', type: CardType.tacocat),
        ],
        targetPlayerId: 'p2',
        chosenCardId: 'chosen-1',
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<PlayCatTrioAction>());
      final r = restored as PlayCatTrioAction;
      expect(r.cards, action.cards);
      expect(r.targetPlayerId, 'p2');
      expect(r.chosenCardId, 'chosen-1');
    });

    test('DefuseBombAction round-trip', () {
      const action = DefuseBombAction(
        playerId: 'p1',
        defuseCard: CardModel(id: 'defuse_1', type: CardType.defuse),
        insertAtPosition: 3,
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<DefuseBombAction>());
      final r = restored as DefuseBombAction;
      expect(r.defuseCard, action.defuseCard);
      expect(r.insertAtPosition, 3);
    });

    test('NopeAction round-trip', () {
      const action = NopeAction(
        playerId: 'p1',
        nopeCard: CardModel(id: 'nope_1', type: CardType.nope),
      );
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<NopeAction>());
      expect((restored as NopeAction).nopeCard, action.nopeCard);
    });

    test('ChooseCardAction round-trip', () {
      const action = ChooseCardAction(playerId: 'p2', cardId: 'card-1');
      final restored = TurnAction.fromJson(action.toJson());
      expect(restored, isA<ChooseCardAction>());
      final r = restored as ChooseCardAction;
      expect(r.playerId, 'p2');
      expect(r.cardId, 'card-1');
    });

    test('fromJson lanza FormatException con un type desconocido', () {
      expect(
        () => TurnAction.fromJson({'type': 'unknown', 'playerId': 'p1'}),
        throwsFormatException,
      );
    });
  });
}
