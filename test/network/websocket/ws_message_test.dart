import 'package:exploding_kittens/network/websocket/websocket_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WsMessage — serialización round-trip', () {
    void roundTrip(WsMessage msg) {
      final restored = WsMessage.fromJson(msg.toJson());
      expect(restored.toJson(), equals(msg.toJson()));
    }

    // ── client → server ────────────────────────────────────────────────────
    test('JoinRoomMessage', () {
      roundTrip(const JoinRoomMessage(playerId: 'p1', name: 'Alice'));
    });

    test('SetReadyMessage true/false', () {
      roundTrip(const SetReadyMessage(ready: true));
      roundTrip(const SetReadyMessage(ready: false));
    });

    test('LeaveRoomMessage', () {
      roundTrip(const LeaveRoomMessage(playerId: 'p1'));
    });

    test('StartGameMessage', () {
      roundTrip(const StartGameMessage());
    });

    // ── server → client ────────────────────────────────────────────────────
    test('RoomStateMessage conserva roomJson', () {
      const payload = {'id': 'room1', 'hostId': 'h1'};
      final msg = RoomStateMessage(roomJson: payload);
      final restored = WsMessage.fromJson(msg.toJson()) as RoomStateMessage;
      expect(restored.roomJson, equals(payload));
    });

    test('GameStartingMessage', () {
      roundTrip(const GameStartingMessage());
    });

    test('PlayerKickedMessage', () {
      roundTrip(const PlayerKickedMessage(reason: 'Host left'));
    });

    test('WsErrorMessage', () {
      roundTrip(const WsErrorMessage(message: 'Room is full'));
    });

    // ── heartbeat ──────────────────────────────────────────────────────────
    test('PingMessage / PongMessage', () {
      roundTrip(const PingMessage());
      roundTrip(const PongMessage());
    });

    // ── phase-5 stubs ──────────────────────────────────────────────────────
    test('GameStateMessage conserva payload', () {
      final msg = GameStateMessage(stateJson: {'turn': 1});
      final restored = WsMessage.fromJson(msg.toJson()) as GameStateMessage;
      expect(restored.stateJson, equals({'turn': 1}));
    });

    test('ActionMessage conserva payload', () {
      final msg = ActionMessage(actionJson: {'type': 'draw'});
      final restored = WsMessage.fromJson(msg.toJson()) as ActionMessage;
      expect(restored.actionJson, equals({'type': 'draw'}));
    });

    test('PlayerReconnectedMessage', () {
      roundTrip(const PlayerReconnectedMessage(playerId: 'p2'));
    });

    // ── tipo desconocido ────────────────────────────────────────────────────
    test('fromJson lanza FormatException en tipo desconocido', () {
      expect(
        () => WsMessage.fromJson({'type': 'unknown_xyz'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
