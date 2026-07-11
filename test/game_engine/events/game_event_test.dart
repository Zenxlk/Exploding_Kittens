import 'package:exploding_kittens/game_engine/events/game_event.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 7, 9, 12, 30);

  group('GameEvent', () {
    test('CardPlayedEvent round-trip', () {
      final event = CardPlayedEvent(
        timestamp: timestamp,
        playerId: 'p1',
        card: const CardModel(id: 'skip_1', type: CardType.skip),
      );
      final restored = GameEvent.fromJson(event.toJson()) as CardPlayedEvent;
      expect(restored.timestamp, timestamp);
      expect(restored.playerId, 'p1');
      expect(restored.card, event.card);
    });

    test('CardDrawnEvent round-trip', () {
      final event = CardDrawnEvent(timestamp: timestamp, playerId: 'p1');
      final restored = GameEvent.fromJson(event.toJson()) as CardDrawnEvent;
      expect(restored.playerId, 'p1');
    });

    test('BombTriggeredEvent round-trip', () {
      final event = BombTriggeredEvent(timestamp: timestamp, playerId: 'p1');
      final restored = GameEvent.fromJson(event.toJson()) as BombTriggeredEvent;
      expect(restored.playerId, 'p1');
    });

    test('BombDefusedEvent round-trip', () {
      final event = BombDefusedEvent(
        timestamp: timestamp,
        playerId: 'p1',
        insertedAtPosition: 5,
      );
      final restored = GameEvent.fromJson(event.toJson()) as BombDefusedEvent;
      expect(restored.playerId, 'p1');
      expect(restored.insertedAtPosition, 5);
    });

    test('PlayerEliminatedEvent round-trip', () {
      final event = PlayerEliminatedEvent(
        timestamp: timestamp,
        playerId: 'p1',
        playerName: 'Alice',
      );
      final restored =
          GameEvent.fromJson(event.toJson()) as PlayerEliminatedEvent;
      expect(restored.playerId, 'p1');
      expect(restored.playerName, 'Alice');
    });

    test('NopedEvent round-trip', () {
      final event =
          NopedEvent(timestamp: timestamp, playerId: 'p1', chainCount: 2);
      final restored = GameEvent.fromJson(event.toJson()) as NopedEvent;
      expect(restored.chainCount, 2);
    });

    test('TurnChangedEvent round-trip', () {
      final event = TurnChangedEvent(
        timestamp: timestamp,
        nextPlayerId: 'p2',
        turnCount: 7,
      );
      final restored = GameEvent.fromJson(event.toJson()) as TurnChangedEvent;
      expect(restored.nextPlayerId, 'p2');
      expect(restored.turnCount, 7);
    });

    test('GameOverEvent round-trip', () {
      final event = GameOverEvent(
        timestamp: timestamp,
        winnerId: 'p1',
        winnerName: 'Alice',
      );
      final restored = GameEvent.fromJson(event.toJson()) as GameOverEvent;
      expect(restored.winnerId, 'p1');
      expect(restored.winnerName, 'Alice');
    });

    test('DeckShuffledEvent round-trip', () {
      final event = DeckShuffledEvent(timestamp: timestamp);
      final restored = GameEvent.fromJson(event.toJson());
      expect(restored, isA<DeckShuffledEvent>());
      expect(restored.timestamp, timestamp);
    });

    test('SeeTheFutureEvent round-trip', () {
      final event = SeeTheFutureEvent(
        timestamp: timestamp,
        playerId: 'p1',
        topCards: const [
          CardModel(id: 'a', type: CardType.attack),
          CardModel(id: 'b', type: CardType.skip),
        ],
      );
      final restored = GameEvent.fromJson(event.toJson()) as SeeTheFutureEvent;
      expect(restored.topCards, event.topCards);
    });

    test('fromJson lanza FormatException con un type desconocido', () {
      expect(
        () => GameEvent.fromJson({
          'type': 'unknown',
          'timestamp': timestamp.toIso8601String(),
        }),
        throwsFormatException,
      );
    });
  });
}
