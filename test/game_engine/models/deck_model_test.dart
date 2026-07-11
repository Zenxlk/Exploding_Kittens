import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeckModel', () {
    test('toJson / fromJson round-trip conserva todos los campos', () {
      const deck = DeckModel(
        drawPile: [
          CardModel(id: 'shuffle_1', type: CardType.shuffle),
          CardModel(id: 'attack_1', type: CardType.attack),
        ],
        discardPile: [CardModel(id: 'skip_1', type: CardType.skip)],
      );

      final restored = DeckModel.fromJson(deck.toJson());
      expect(restored, equals(deck));
    });

    test('fromJson maneja pilas vacías', () {
      const deck = DeckModel(drawPile: [], discardPile: []);
      final restored = DeckModel.fromJson(deck.toJson());
      expect(restored, equals(deck));
    });
  });
}
