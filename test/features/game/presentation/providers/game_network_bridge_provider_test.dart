import 'package:exploding_kittens/features/game/presentation/providers/game_network_bridge_provider.dart';
import 'package:exploding_kittens/features/game/presentation/providers/game_providers.dart';
import 'package:exploding_kittens/features/lobby/presentation/providers/lobby_providers.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/network/websocket/websocket_client.dart';
import 'package:exploding_kittens/network/websocket/websocket_message.dart';
import 'package:exploding_kittens/network/websocket/websocket_server.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake: solo necesitamos que `wsServer` devuelva el servidor real de la
// prueba; el resto del estado del lobby no lo toca el puente.
class _FakeLobbyNotifier extends LobbyNotifier {
  _FakeLobbyNotifier(this._server);
  final WsServer _server;

  @override
  LobbyState build() => const LobbyIdle();

  @override
  WsServer? get wsServer => _server;
}

void main() {
  group('gameNetworkBridgeProvider', () {
    late WsServer server;
    late WsClient hostClient;
    late ProviderContainer container;

    setUp(() async {
      server = await WsServer.start(hostId: 'host', hostName: 'Host', port: 0);
      hostClient = await WsClient.connect(
        hostAddress: '127.0.0.1',
        playerId: 'host',
        playerName: 'Host',
        port: server.port,
      );
      container = ProviderContainer(
        overrides: [
          lobbyProvider.overrideWith(() => _FakeLobbyNotifier(server))
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await hostClient.close(playerId: 'host');
      await server.close();
    });

    test(
      'una ActionMessage válida se aplica al motor real y retransmite el '
      'nuevo GameState a todos los clientes',
      () async {
        final gameNotifier = container.read(gameProvider.notifier);
        gameNotifier.startLocalGame(
          const [
            PlayerModel(id: 'host', name: 'Host', hand: []),
            PlayerModel(id: 'p2', name: 'Bob', hand: []),
          ],
          const GameConfig(playerCount: 2),
        );
        container.read(gameNetworkBridgeProvider); // activa el puente

        final currentPlayerId =
            (gameNotifier.state as GameRunning).state.turn.currentPlayerId;

        // Solo nos importa la retransmisión posterior al draw (turnCount 1);
        // el join del propio hostClient también puede disparar un
        // onPlayerReconnected -> markPlayerReconnected en la carrera contra
        // el cliente, pero ese es ahora un no-op que no retransmite nada.
        final received = hostClient.messages
            .firstWhere(
              (m) => m is GameStateMessage && m.stateJson['turnCount'] == 1,
            )
            .timeout(const Duration(seconds: 3));

        hostClient.send(ActionMessage(
          actionJson: {'type': 'draw_card', 'playerId': currentPlayerId},
        ));

        final msg = await received as GameStateMessage;
        final relayedState = GameState.fromJson(msg.stateJson);
        expect(
          relayedState,
          (gameNotifier.state as GameRunning).state,
        );
      },
    );

    test(
      'una ActionMessage inválida responde ActionRejectedMessage solo a '
      'quien la mandó, sin tocar el estado',
      () async {
        final gameNotifier = container.read(gameProvider.notifier);
        gameNotifier.startLocalGame(
          const [
            PlayerModel(id: 'host', name: 'Host', hand: []),
            PlayerModel(id: 'p2', name: 'Bob', hand: []),
          ],
          const GameConfig(playerCount: 2),
        );
        container.read(gameNetworkBridgeProvider);

        final stateBefore = (gameNotifier.state as GameRunning).state;

        final rejected = hostClient.messages
            .firstWhere((m) => m is ActionRejectedMessage)
            .timeout(const Duration(seconds: 3));

        // 'p2' no tiene el turno (currentPlayerId es el primer jugador,
        // 'host') -> GameRules.validate debería rechazarla.
        hostClient.send(const ActionMessage(
          actionJson: {'type': 'draw_card', 'playerId': 'p2'},
        ));

        final msg = await rejected as ActionRejectedMessage;
        expect(msg.message, isNotEmpty);
        expect(
          (gameNotifier.state as GameRunning).state,
          stateBefore,
        );
      },
    );

    test(
      'un GameEvent del motor se retransmite como GameEventMessage',
      () async {
        final gameNotifier = container.read(gameProvider.notifier);
        gameNotifier.startLocalGame(
          const [
            PlayerModel(id: 'host', name: 'Host', hand: []),
            PlayerModel(id: 'p2', name: 'Bob', hand: []),
          ],
          const GameConfig(playerCount: 2),
        );
        container.read(gameNetworkBridgeProvider);

        final currentPlayerId =
            (gameNotifier.state as GameRunning).state.turn.currentPlayerId;

        final received = hostClient.messages
            .firstWhere((m) => m is GameEventMessage)
            .timeout(const Duration(seconds: 3));

        hostClient.send(ActionMessage(
          actionJson: {'type': 'draw_card', 'playerId': currentPlayerId},
        ));

        final msg = await received;
        expect(msg, isA<GameEventMessage>());
      },
    );

    test('sin wsServer (no-host) el provider no hace nada', () {
      final noHostContainer = ProviderContainer(
        overrides: [
          lobbyProvider.overrideWith(() => _NoServerLobbyNotifier()),
        ],
      );
      addTearDown(noHostContainer.dispose);

      expect(
        () => noHostContainer.read(gameNetworkBridgeProvider),
        returnsNormally,
      );
    });
  });
}

class _NoServerLobbyNotifier extends LobbyNotifier {
  @override
  LobbyState build() => const LobbyIdle();

  @override
  WsServer? get wsServer => null;
}
