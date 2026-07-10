// Messages exchanged between the WebSocket server (host) and clients.
//
// Naming convention:
//   Client → Server : JoinRoom, SetReady, LeaveRoom, StartGame, Action,
//                      PlayerReconnected
//   Server → Client : RoomState, GameStarting, PlayerKicked, WsError,
//                      GameState (broadcast), GameEvent (broadcast),
//                      ActionRejected (targeted)
//   Both directions : Ping, Pong

sealed class WsMessage {
  const WsMessage();

  Map<String, dynamic> toJson();

  // Deserializes any incoming JSON frame into the correct subtype.
  static WsMessage fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      // ── lobby ────────────────────────────────────────────────────────────
      'join_room' => JoinRoomMessage._fromJson(json),
      'set_ready' => SetReadyMessage._fromJson(json),
      'leave_room' => LeaveRoomMessage._fromJson(json),
      'start_game' => const StartGameMessage(),
      'room_state' => RoomStateMessage._fromJson(json),
      'game_starting' => const GameStartingMessage(),
      'player_kicked' => PlayerKickedMessage._fromJson(json),
      'ws_error' => WsErrorMessage._fromJson(json),
      // ── heartbeat ────────────────────────────────────────────────────────
      'ping' => const PingMessage(),
      'pong' => const PongMessage(),
      // ── in-game (Fase 5) ─────────────────────────────────────────────────
      'game_state' => GameStateMessage._fromJson(json),
      'action' => ActionMessage._fromJson(json),
      'player_reconnected' => PlayerReconnectedMessage._fromJson(json),
      'game_event' => GameEventMessage._fromJson(json),
      'action_rejected' => ActionRejectedMessage._fromJson(json),
      //
      final t => throw FormatException('Unknown WsMessage type: $t'),
    };
  }
}

// ── Client → Server ──────────────────────────────────────────────────────────

final class JoinRoomMessage extends WsMessage {
  const JoinRoomMessage({required this.playerId, required this.name});

  final String playerId;
  final String name;

  factory JoinRoomMessage._fromJson(Map<String, dynamic> j) => JoinRoomMessage(
      playerId: j['playerId'] as String, name: j['name'] as String);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'join_room', 'playerId': playerId, 'name': name};
}

final class SetReadyMessage extends WsMessage {
  const SetReadyMessage({required this.ready});

  final bool ready;

  factory SetReadyMessage._fromJson(Map<String, dynamic> j) =>
      SetReadyMessage(ready: j['ready'] as bool);

  @override
  Map<String, dynamic> toJson() => {'type': 'set_ready', 'ready': ready};
}

final class LeaveRoomMessage extends WsMessage {
  const LeaveRoomMessage({required this.playerId});

  final String playerId;

  factory LeaveRoomMessage._fromJson(Map<String, dynamic> j) =>
      LeaveRoomMessage(playerId: j['playerId'] as String);

  @override
  Map<String, dynamic> toJson() => {'type': 'leave_room', 'playerId': playerId};
}

// Sent by the host only; no payload needed.
final class StartGameMessage extends WsMessage {
  const StartGameMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'start_game'};
}

// ── Server → Client ──────────────────────────────────────────────────────────

// Broadcast by the server after every room change.
// roomJson carries the full LobbyRoom snapshot (serialized by the repository).
final class RoomStateMessage extends WsMessage {
  const RoomStateMessage({required this.roomJson});

  final Map<String, dynamic> roomJson;

  factory RoomStateMessage._fromJson(Map<String, dynamic> j) =>
      RoomStateMessage(roomJson: j['room'] as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson() => {'type': 'room_state', 'room': roomJson};
}

// Sent by the server when the host triggers startGame successfully.
final class GameStartingMessage extends WsMessage {
  const GameStartingMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'game_starting'};
}

// Sent to a specific client when it is removed from the room.
final class PlayerKickedMessage extends WsMessage {
  const PlayerKickedMessage({required this.reason});

  final String reason;

  factory PlayerKickedMessage._fromJson(Map<String, dynamic> j) =>
      PlayerKickedMessage(reason: j['reason'] as String);

  @override
  Map<String, dynamic> toJson() => {'type': 'player_kicked', 'reason': reason};
}

// Generic error response from the server.
final class WsErrorMessage extends WsMessage {
  const WsErrorMessage({required this.message});

  final String message;

  factory WsErrorMessage._fromJson(Map<String, dynamic> j) =>
      WsErrorMessage(message: j['message'] as String);

  @override
  Map<String, dynamic> toJson() => {'type': 'ws_error', 'message': message};
}

// ── Heartbeat ────────────────────────────────────────────────────────────────

final class PingMessage extends WsMessage {
  const PingMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'ping'};
}

final class PongMessage extends WsMessage {
  const PongMessage();
  @override
  Map<String, dynamic> toJson() => {'type': 'pong'};
}

// ── In-game messages (Fase 5) ────────────────────────────────────────────────

// Full GameState snapshot; broadcast by host after every action.
final class GameStateMessage extends WsMessage {
  const GameStateMessage({required this.stateJson});

  final Map<String, dynamic> stateJson;

  factory GameStateMessage._fromJson(Map<String, dynamic> j) =>
      GameStateMessage(stateJson: j['payload'] as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson() => {'type': 'game_state', 'payload': stateJson};
}

// Player action forwarded to the host engine.
final class ActionMessage extends WsMessage {
  const ActionMessage({required this.actionJson});

  final Map<String, dynamic> actionJson;

  factory ActionMessage._fromJson(Map<String, dynamic> j) =>
      ActionMessage(actionJson: j['payload'] as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson() => {'type': 'action', 'payload': actionJson};
}

// Notifies the host that a previously disconnected player is back.
final class PlayerReconnectedMessage extends WsMessage {
  const PlayerReconnectedMessage({required this.playerId});

  final String playerId;

  factory PlayerReconnectedMessage._fromJson(Map<String, dynamic> j) =>
      PlayerReconnectedMessage(playerId: j['playerId'] as String);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'player_reconnected', 'playerId': playerId};
}

// A single GameEvent; broadcast by host alongside GameState so non-host
// devices (with no local engine) can still trigger sounds/animations.
final class GameEventMessage extends WsMessage {
  const GameEventMessage({required this.eventJson});

  final Map<String, dynamic> eventJson;

  factory GameEventMessage._fromJson(Map<String, dynamic> j) =>
      GameEventMessage(eventJson: j['payload'] as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson() => {'type': 'game_event', 'payload': eventJson};
}

// Sent by host to the specific client whose ActionMessage failed
// GameRules.validate (InvalidActionException), instead of silently dropping it.
final class ActionRejectedMessage extends WsMessage {
  const ActionRejectedMessage({required this.message});

  final String message;

  factory ActionRejectedMessage._fromJson(Map<String, dynamic> j) =>
      ActionRejectedMessage(message: j['message'] as String);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'action_rejected', 'message': message};
}
