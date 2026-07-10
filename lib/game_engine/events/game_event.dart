import '../models/card/card_model.dart';

/// Todos los eventos que el motor emite; la UI los escucha para animaciones y sonidos.
///
/// Se serializa con un discriminador `type` (mismo patrón que `TurnAction` y
/// `WsMessage`): en Fase 5 los dispositivos no-host no tienen motor local, así
/// que su único origen de `GameEvent` es lo que el host reenvía por red.
sealed class GameEvent {
  const GameEvent({required this.timestamp});
  final DateTime timestamp;

  Map<String, dynamic> toJson();

  static GameEvent fromJson(Map<String, dynamic> j) {
    final timestamp = DateTime.parse(j['timestamp'] as String);
    return switch (j['type'] as String) {
      'card_played' => CardPlayedEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
          card: CardModel.fromJson(j['card'] as Map<String, dynamic>),
        ),
      'card_drawn' => CardDrawnEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
        ),
      'bomb_triggered' => BombTriggeredEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
        ),
      'bomb_defused' => BombDefusedEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
          insertedAtPosition: j['insertedAtPosition'] as int,
        ),
      'player_eliminated' => PlayerEliminatedEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
          playerName: j['playerName'] as String,
        ),
      'noped' => NopedEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
          chainCount: j['chainCount'] as int,
        ),
      'turn_changed' => TurnChangedEvent(
          timestamp: timestamp,
          nextPlayerId: j['nextPlayerId'] as String,
          turnCount: j['turnCount'] as int,
        ),
      'game_over' => GameOverEvent(
          timestamp: timestamp,
          winnerId: j['winnerId'] as String,
          winnerName: j['winnerName'] as String,
        ),
      'deck_shuffled' => DeckShuffledEvent(timestamp: timestamp),
      'see_the_future' => SeeTheFutureEvent(
          timestamp: timestamp,
          playerId: j['playerId'] as String,
          topCards: (j['topCards'] as List)
              .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
              .toList(),
        ),
      final t => throw FormatException('Unknown GameEvent type: $t'),
    };
  }
}

final class CardPlayedEvent extends GameEvent {
  const CardPlayedEvent({
    required super.timestamp,
    required this.playerId,
    required this.card,
  });
  final String playerId;
  final CardModel card;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'card_played',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
        'card': card.toJson(),
      };
}

final class CardDrawnEvent extends GameEvent {
  const CardDrawnEvent({
    required super.timestamp,
    required this.playerId,
  });
  final String playerId;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'card_drawn',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
      };
}

final class BombTriggeredEvent extends GameEvent {
  const BombTriggeredEvent({
    required super.timestamp,
    required this.playerId,
  });
  final String playerId;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'bomb_triggered',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
      };
}

final class BombDefusedEvent extends GameEvent {
  const BombDefusedEvent({
    required super.timestamp,
    required this.playerId,
    required this.insertedAtPosition,
  });
  final String playerId;
  final int insertedAtPosition;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'bomb_defused',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
        'insertedAtPosition': insertedAtPosition,
      };
}

final class PlayerEliminatedEvent extends GameEvent {
  const PlayerEliminatedEvent({
    required super.timestamp,
    required this.playerId,
    required this.playerName,
  });
  final String playerId;
  final String playerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'player_eliminated',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
        'playerName': playerName,
      };
}

final class NopedEvent extends GameEvent {
  const NopedEvent({
    required super.timestamp,
    required this.playerId,
    required this.chainCount,
  });
  final String playerId;
  final int chainCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'noped',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
        'chainCount': chainCount,
      };
}

final class TurnChangedEvent extends GameEvent {
  const TurnChangedEvent({
    required super.timestamp,
    required this.nextPlayerId,
    required this.turnCount,
  });
  final String nextPlayerId;
  final int turnCount;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'turn_changed',
        'timestamp': timestamp.toIso8601String(),
        'nextPlayerId': nextPlayerId,
        'turnCount': turnCount,
      };
}

final class GameOverEvent extends GameEvent {
  const GameOverEvent({
    required super.timestamp,
    required this.winnerId,
    required this.winnerName,
  });
  final String winnerId;
  final String winnerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'game_over',
        'timestamp': timestamp.toIso8601String(),
        'winnerId': winnerId,
        'winnerName': winnerName,
      };
}

final class DeckShuffledEvent extends GameEvent {
  const DeckShuffledEvent({required super.timestamp});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'deck_shuffled',
        'timestamp': timestamp.toIso8601String(),
      };
}

final class SeeTheFutureEvent extends GameEvent {
  const SeeTheFutureEvent({
    required super.timestamp,
    required this.playerId,
    required this.topCards,
  });
  final String playerId;
  final List<CardModel> topCards;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'see_the_future',
        'timestamp': timestamp.toIso8601String(),
        'playerId': playerId,
        'topCards': topCards.map((c) => c.toJson()).toList(),
      };
}
