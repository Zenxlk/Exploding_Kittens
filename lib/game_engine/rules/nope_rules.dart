import '../models/game/game_state.dart';

/// Lógica de la cadena de Nope.
/// Nope cancela la acción anterior.
/// Nope-a-Nope re-activa la acción.
/// Se puede encadenar indefinidamente durante la ventana de tiempo.
abstract final class NopeRules {
  /// ¿La acción pendiente está actualmente cancelada?
  static bool isActionCancelled(GameState state) => state.turn.isNoped;

  /// ¿Se puede seguir añadiendo Nopes? (ventana abierta y hay acción pendiente)
  static bool canAddNope(GameState state) =>
      state.pendingAction != null &&
      state.turn.phase.name == 'nopeWindow';

  /// Aplica un Nope: incrementa el contador de la cadena.
  static int incrementNopeChain(int current) => current + 1;
}
