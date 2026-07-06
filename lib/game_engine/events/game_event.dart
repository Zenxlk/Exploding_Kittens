import '../models/card/card_model.dart';

/// Todos los eventos que el motor emite; la UI los escucha para animaciones y sonidos.
sealed class GameEvent {
  const GameEvent({required this.timestamp});
  final DateTime timestamp;
}

final class CardPlayedEvent extends GameEvent {
  const CardPlayedEvent({
    required super.timestamp,
    required this.playerId,
    required this.card,
  });
  final String playerId;
  final CardModel card;
}

final class CardDrawnEvent extends GameEvent {
  const CardDrawnEvent({
    required super.timestamp,
    required this.playerId,
  });
  final String playerId;
}

final class BombTriggeredEvent extends GameEvent {
  const BombTriggeredEvent({
    required super.timestamp,
    required this.playerId,
  });
  final String playerId;
}

final class BombDefusedEvent extends GameEvent {
  const BombDefusedEvent({
    required super.timestamp,
    required this.playerId,
    required this.insertedAtPosition,
  });
  final String playerId;
  final int insertedAtPosition;
}

final class PlayerEliminatedEvent extends GameEvent {
  const PlayerEliminatedEvent({
    required super.timestamp,
    required this.playerId,
    required this.playerName,
  });
  final String playerId;
  final String playerName;
}

final class NopedEvent extends GameEvent {
  const NopedEvent({
    required super.timestamp,
    required this.playerId,
    required this.chainCount,
  });
  final String playerId;
  final int chainCount;
}

final class TurnChangedEvent extends GameEvent {
  const TurnChangedEvent({
    required super.timestamp,
    required this.nextPlayerId,
    required this.turnCount,
  });
  final String nextPlayerId;
  final int turnCount;
}

final class GameOverEvent extends GameEvent {
  const GameOverEvent({
    required super.timestamp,
    required this.winnerId,
    required this.winnerName,
  });
  final String winnerId;
  final String winnerName;
}

final class DeckShuffledEvent extends GameEvent {
  const DeckShuffledEvent({required super.timestamp});
}

final class SeeTheFutureEvent extends GameEvent {
  const SeeTheFutureEvent({
    required super.timestamp,
    required this.playerId,
    required this.topCards,
  });
  final String playerId;
  final List<CardModel> topCards;
}
