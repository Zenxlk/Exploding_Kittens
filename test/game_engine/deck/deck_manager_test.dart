import 'package:exploding_kittens/game_engine/deck/deck_manager.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card1 = CardModel(id: 'nope_1', type: CardType.nope);
  const card2 = CardModel(id: 'attack_1', type: CardType.attack);
  const card3 = CardModel(id: 'skip_1', type: CardType.skip);

  DeckModel makeDeck(List<CardModel> pile) =>
      DeckModel(drawPile: pile, discardPile: const []);

  group('DeckManager.drawTop', () {
    test('retorna la primera carta', () {
      final original = makeDeck([card1, card2, card3]);
      final result = DeckManager.drawTop(original);
      expect(result.drawn, equals(card1));
      expect(result.deck.drawPile, equals([card2, card3]));
    });

    test('lanza StateError con mazo vacío', () {
      final deck = makeDeck([]);
      expect(() => DeckManager.drawTop(deck), throwsStateError);
    });
  });

  group('DeckManager.insertAt', () {
    test('inserta en posición 0 (primera)', () {
      final deck = makeDeck([card1, card2]);
      final result = DeckManager.insertAt(deck, card3, 0);
      expect(result.drawPile.first, equals(card3));
    });

    test('inserta al final cuando posición > longitud', () {
      final deck = makeDeck([card1, card2]);
      final result = DeckManager.insertAt(deck, card3, 99);
      expect(result.drawPile.last, equals(card3));
    });
  });

  group('DeckManager.peekTop', () {
    test('devuelve N cartas sin extraerlas', () {
      final deck = makeDeck([card1, card2, card3]);
      final top = DeckManager.peekTop(deck, 2);
      expect(top, equals([card1, card2]));
      expect(deck.drawPile.length, equals(3));
    });
  });
}
