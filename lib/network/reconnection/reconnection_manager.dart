import 'dart:async';

import 'package:exploding_kittens/core/constants/game_constants.dart';

/// Lleva la cuenta del grace period de cada jugador desconectado a mitad de
/// partida. No sabe nada de `GameState`/`WsServer` — el puente de red↔motor
/// (lado host) es quien conecta `trackDisconnect`/`cancelIfPending` a los
/// hooks `onPlayerDisconnected`/`onPlayerReconnected` de `WsServer`, y quien
/// decide qué hacer cuando expira (eliminar al jugador de la partida).
class ReconnectionManager {
  ReconnectionManager({
    Duration graceTimeout = const Duration(
      seconds: GameConstants.reconnectTimeoutSeconds,
    ),
  }) : _graceTimeout = graceTimeout;

  final Duration _graceTimeout;
  final _timers = <String, Timer>{};

  /// Arranca (o reinicia) el grace period de [playerId]; si no reconecta
  /// antes de que expire, se llama a [onExpired] con su id.
  void trackDisconnect(
      String playerId, void Function(String playerId) onExpired) {
    _timers[playerId]?.cancel();
    _timers[playerId] = Timer(_graceTimeout, () {
      _timers.remove(playerId);
      onExpired(playerId);
    });
  }

  /// Cancela el grace period de [playerId] si había uno corriendo (reconectó
  /// a tiempo). No hace nada si no había ninguno pendiente.
  void cancelIfPending(String playerId) {
    _timers.remove(playerId)?.cancel();
  }

  bool isPending(String playerId) => _timers.containsKey(playerId);

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
