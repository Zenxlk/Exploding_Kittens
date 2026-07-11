import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:exploding_kittens/features/lobby/presentation/providers/lobby_providers.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:exploding_kittens/network/reconnection/reconnection_manager.dart';
import 'package:exploding_kittens/network/websocket/websocket_message.dart';
import 'game_providers.dart';

/// Puente host↔red (Fase 5): mientras el motor real solo corre en el
/// dispositivo host (`LocalGameGateway`), este provider es quien lo conecta
/// con los demás jugadores por WebSocket. Solo hace algo si el dispositivo
/// actual es el host de una sala — en cualquier otro caso es un no-op.
///
/// `GameScreen` lo activa (vía `ref.watch`/`ref.read`) al entrar como host,
/// antes de arrancar la partida, para no perder el primer `GameState`.
final gameNetworkBridgeProvider = Provider<void>((ref) {
  final wsServer = ref.read(lobbyProvider.notifier).wsServer;
  if (wsServer == null) return;

  final gameNotifier = ref.read(gameProvider.notifier);
  final reconnection = ReconnectionManager();

  // Cliente → host: decodifica la acción y la aplica al motor real; si
  // GameRules la rechaza, se lo contesta solo a quien la mandó en vez de
  // dejarlo perdido (antes de Fase 5, ActionMessage ni se enrutaba).
  final actionSub = wsServer.actionMessages.listen((entry) {
    final action = TurnAction.fromJson(entry.actionJson);
    final error = gameNotifier.applyAction(action);
    if (error != null) {
      wsServer.sendToPlayer(
        entry.playerId,
        ActionRejectedMessage(message: error),
      );
    }
  });

  // Host → todos: cada cambio de estado/evento se retransmite tal cual,
  // incluido el instante en que la partida termina (rawStates, no `state`).
  final stateSub = gameNotifier.rawStates.listen((gameState) {
    wsServer.broadcast(GameStateMessage(stateJson: gameState.toJson()));
  });
  final eventSub = gameNotifier.events.listen((event) {
    wsServer.broadcast(GameEventMessage(eventJson: event.toJson()));
  });

  // Desconexión/reconexión de red → ReconnectionManager (grace period) →
  // motor (marca visual inmediata + eliminación si expira sin volver).
  wsServer.onPlayerDisconnected = (playerId) {
    gameNotifier.markPlayerDisconnected(playerId);
    reconnection.trackDisconnect(playerId, gameNotifier.eliminateForDisconnect);
  };
  wsServer.onPlayerReconnected = (playerId) {
    reconnection.cancelIfPending(playerId);
    gameNotifier.markPlayerReconnected(playerId);
  };

  ref.onDispose(() {
    actionSub.cancel();
    stateSub.cancel();
    eventSub.cancel();
    wsServer.onPlayerDisconnected = null;
    wsServer.onPlayerReconnected = null;
    reconnection.dispose();
  });
});
