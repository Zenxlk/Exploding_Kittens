import '../models/game/game_state.dart';
import '../models/player/player_status.dart';

/// Reglas de transición y secuencia de turno.
abstract final class TurnRules {
  /// ¿El turno actual ha terminado? (jugador robó y no hay acciones pendientes)
  static bool isTurnOver(GameState state) => state.turn.phase.name == 'ended';

  /// Devuelve el id del siguiente jugador vivo en sentido horario.
  static String nextPlayerId(GameState state) {
    final alive =
        state.players.where((p) => p.status == PlayerStatus.active).toList();
    if (alive.isEmpty) throw StateError('No hay jugadores vivos');

    final currentIndex =
        alive.indexWhere((p) => p.id == state.turn.currentPlayerId);
    final nextIndex = (currentIndex + 1) % alive.length;
    return alive[nextIndex].id;
  }

  /// ¿Cuántos turnos extra tiene el jugador por efecto de Attack?
  static int attackTurnsLeft(GameState state) =>
      state.turn.actionsLeft > 1 ? state.turn.actionsLeft - 1 : 0;
}
