import '../models/game/game_result.dart';
import '../models/game/game_state.dart';
import '../models/player/player_status.dart';

abstract final class WinCondition {
  /// Devuelve el GameResult si la partida tiene ganador, null si sigue.
  static GameResult? check(GameState state) {
    final alive = state.alivePlayers;
    if (alive.length != 1) return null;

    final winner = alive.first;
    return GameResult(
      winnerId: winner.id,
      winnerName: winner.name,
      totalTurns: state.turnCount,
      eliminationOrder: state.players
          .where((p) => p.status == PlayerStatus.eliminated)
          .map((p) => p.id)
          .toList(),
    );
  }
}
