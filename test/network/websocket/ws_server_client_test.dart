import 'package:exploding_kittens/features/lobby/domain/models/lobby_status.dart';
import 'package:exploding_kittens/network/websocket/websocket_client.dart';
import 'package:exploding_kittens/network/websocket/websocket_message.dart';
import 'package:exploding_kittens/network/websocket/websocket_server.dart';
import 'package:flutter_test/flutter_test.dart';

// Integration tests: real WsServer + WsClient on loopback.
// Each test binds on port 0 (OS-assigned) to avoid collisions.
void main() {
  // Helpers
  Future<WsServer> startServer({String hostId = 'h1', String hostName = 'Host'}) =>
      WsServer.start(hostId: hostId, hostName: hostName, port: 0);

  Future<WsClient> connectClient({
    required int port,
    String playerId = 'p1',
    String playerName = 'Alice',
  }) =>
      WsClient.connect(
        hostAddress: '127.0.0.1',
        playerId: playerId,
        playerName: playerName,
        port: port,
      );

  // ── conexión básica ──────────────────────────────────────────────────────
  group('WsServer — conexión', () {
    test('el servidor arranca y expone el puerto asignado', () async {
      final server = await startServer();
      expect(server.port, isNonZero);
      expect(server.isRunning, isTrue);
      await server.close();
    });

    test('el host aparece en la sala inicial', () async {
      final server = await startServer();
      expect(server.currentRoom!.players, hasLength(1));
      expect(server.currentRoom!.players.first.isHost, isTrue);
      await server.close();
    });
  });

  // ── join / leave ─────────────────────────────────────────────────────────
  group('WsServer — join / leave', () {
    test('un cliente que se une aparece en la sala', () async {
      final server = await startServer();

      // Suscribirse antes de conectar para no perder el evento
      final roomUpdate = server.roomStream.first;
      final client = await connectClient(port: server.port);

      final room = await roomUpdate.timeout(const Duration(seconds: 3));
      expect(room.players, hasLength(2));
      expect(room.players.any((p) => p.id == 'p1'), isTrue);

      await client.close(playerId: 'p1');
      await server.close();
    });

    test('un cliente que se va se elimina de la sala', () async {
      final server = await startServer();
      final client = await connectClient(port: server.port);

      // Esperar join
      await server.roomStream
          .firstWhere((r) => r.players.length == 2)
          .timeout(const Duration(seconds: 3));

      // Leave
      final afterLeave = server.roomStream
          .firstWhere((r) => r.players.length == 1)
          .timeout(const Duration(seconds: 3));

      await client.close(playerId: 'p1');
      final room = await afterLeave;
      expect(room.players, hasLength(1));

      await server.close();
    });
  });

  // ── ready / start ────────────────────────────────────────────────────────
  group('WsServer — ready y start', () {
    test('SetReady actualiza el estado del jugador en la sala', () async {
      final server = await startServer();
      final client = await connectClient(port: server.port);

      // Esperar a que el join se procese
      await server.roomStream
          .firstWhere((r) => r.players.length == 2)
          .timeout(const Duration(seconds: 3));

      final readyUpdate = server.roomStream
          .firstWhere((r) => r.players.any((p) => p.id == 'p1' && p.isReady))
          .timeout(const Duration(seconds: 3));

      client.send(const SetReadyMessage(ready: true));
      final room = await readyUpdate;
      expect(room.players.firstWhere((p) => p.id == 'p1').isReady, isTrue);

      await client.close(playerId: 'p1');
      await server.close();
    });

    test('startGame cambia el status a starting cuando canStart es true', () async {
      final server = await startServer();

      // Host se conecta a su propio servidor
      final hostClient = await connectClient(
        port: server.port,
        playerId: 'h1',
        playerName: 'Host',
      );

      // Un segundo jugador se une y se pone listo
      final guest = await connectClient(
        port: server.port,
        playerId: 'p2',
        playerName: 'Bob',
      );

      await server.roomStream
          .firstWhere((r) => r.players.length == 2)
          .timeout(const Duration(seconds: 3));

      guest.send(const SetReadyMessage(ready: true));

      await server.roomStream
          .firstWhere((r) => r.canStart)
          .timeout(const Duration(seconds: 3));

      final startingRoom = server.roomStream
          .firstWhere((r) => r.status == LobbyStatus.starting)
          .timeout(const Duration(seconds: 3));

      hostClient.send(const StartGameMessage());
      final room = await startingRoom;
      expect(room.status, equals(LobbyStatus.starting));

      await hostClient.close(playerId: 'h1');
      await guest.close(playerId: 'p2');
      await server.close();
    });

    test('startGame con canStart false no cambia el status', () async {
      final server = await startServer();
      final hostClient = await connectClient(
        port: server.port,
        playerId: 'h1',
        playerName: 'Host',
      );

      // Solo el host — canStart == false
      hostClient.send(const StartGameMessage());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(server.currentRoom!.status, equals(LobbyStatus.waiting));

      await hostClient.close(playerId: 'h1');
      await server.close();
    });
  });

  // ── WsClient ─────────────────────────────────────────────────────────────
  group('WsClient', () {
    test('lastRoom se cachea tras el primer RoomStateMessage', () async {
      final server = await startServer();
      final client = await connectClient(port: server.port);

      // Esperar que llegue el RoomStateMessage al cliente
      await client.roomStream.first.timeout(const Duration(seconds: 3));

      expect(client.lastRoom, isNotNull);
      expect(client.lastRoom!.players, isNotEmpty);

      await client.close(playerId: 'p1');
      await server.close();
    });

    test('isConnected es false después de close()', () async {
      final server = await startServer();
      final client = await connectClient(port: server.port);
      expect(client.isConnected, isTrue);

      await client.close(playerId: 'p1');
      expect(client.isConnected, isFalse);

      await server.close();
    });
  });
}
