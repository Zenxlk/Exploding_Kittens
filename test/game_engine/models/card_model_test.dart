import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardType', () {
    test('isCatCard reconoce las cartas gato', () {
      expect(CardType.tacocat.isCatCard, isTrue);
      expect(CardType.cattermelon.isCatCard, isTrue);
      expect(CardType.nope.isCatCard, isFalse);
      expect(CardType.explodingKitten.isCatCard, isFalse);
    });

    test('isPlayable excluye explodingKitten y defuse', () {
      expect(CardType.explodingKitten.isPlayable, isFalse);
      expect(CardType.defuse.isPlayable, isFalse);
      expect(CardType.nope.isPlayable, isTrue);
      expect(CardType.attack.isPlayable, isTrue);
    });

    test('requiresTarget solo es true para favor', () {
      expect(CardType.favor.requiresTarget, isTrue);
      expect(CardType.attack.requiresTarget, isFalse);
    });
  });

  group('CardModel', () {
    test('dos cartas con mismo id son iguales', () {
      const a = CardModel(id: 'nope_1', type: CardType.nope);
      const b = CardModel(id: 'nope_1', type: CardType.nope);
      expect(a, equals(b));
    });

    test('cartas con ids distintos son distintas', () {
      const a = CardModel(id: 'nope_1', type: CardType.nope);
      const b = CardModel(id: 'nope_2', type: CardType.nope);
      expect(a, isNot(equals(b)));
    });

    test('toJson / fromJson round-trip conserva todos los campos', () {
      const card = CardModel(id: 'tacocat_3', type: CardType.tacocat);
      final restored = CardModel.fromJson(card.toJson());
      expect(restored, equals(card));
    });
  });
}
