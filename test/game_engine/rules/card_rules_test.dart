import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/rules/card_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
