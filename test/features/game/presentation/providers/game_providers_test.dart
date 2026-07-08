import 'package:exploding_kittens/core/errors/exceptions.dart';
import 'package:exploding_kittens/features/game/domain/i_game_gateway.dart';
import 'package:exploding_kittens/features/game/presentation/providers/game_providers.dart';
import 'package:exploding_kittens/game_engine/events/game_event.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_result.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _state({
  TurnPhase phase = TurnPhase.playing,
  GamePhase gamePhase = GamePhase.playing,
  GameResult? result,
}) {
  return GameState(
    id: 'g1',
    config: const GameConfig(playerCount: 2),
    players: const [PlayerModel(id: 'p1', name: 'A', hand: [])],
    deck: const DeckModel(drawPile: [], discardPile: []),
    turn: TurnModel(currentPlayerId: 'p1', phase: phase),
    phase: gamePhase,
    result: result,
  );
}

class _FakeGameGateway implements IGameGateway {
  GameState Function(List<PlayerModel>, GameConfig)? onStart;
  GameState Function(TurnAction)? onApply;
  GameState Function()? onResolve;
  int applyCalls = 0;
  int resolveCalls = 0;

  @override
  Stream<GameEvent> get events => const Stream.empty();

  @override
  GameState startGame(List<PlayerModel> players, GameConfig config) =>
      onStart!(players, config);

  @override
  GameState apply(TurnAction action) {
    applyCalls++;
    return onApply!(action);
  }

  @override
  GameState resolveNopeWindow() {
    resolveCalls++;
    return onResolve!();
  }
}

void main() {
  group('GameNotifier', () {
    late _FakeGameGateway gateway;
    late ProviderContainer container;

    setUp(() {
      gateway = _FakeGameGateway();
      container = ProviderContainer(
        overrides: [
          gameProvider.overrideWith(
            () => GameNotifier(
              gateway: gateway,
              nopeWindowDuration: const Duration(milliseconds: 5),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('empieza en GameIdle', () {
      expect(container.read(gameProvider), isA<GameIdle>());
    });

    test('startLocalGame pasa a GameRunning con el estado del gateway', () {
      final started = _state();
      gateway.onStart = (_, __) => started;

      container.read(gameProvider.notifier).startLocalGame(
        const [PlayerModel(id: 'p1', name: 'A', hand: [])],
        const GameConfig(playerCount: 2),
      );

      final sessionState = container.read(gameProvider);
      expect(sessionState, isA<GameRunning>());
      expect((sessionState as GameRunning).state, started);
    });

    test(
      'una acción inválida deja un error transitorio sin perder el estado',
      () {
        final running = _state();
        gateway.onStart = (_, __) => running;
        gateway.onApply =
            (_) => throw const InvalidActionException('no es tu turno');

        final notifier = container.read(gameProvider.notifier);
        notifier.startLocalGame(const [], const GameConfig(playerCount: 2));
        notifier.drawCard('p1');

        final sessionState = container.read(gameProvider) as GameRunning;
        expect(sessionState.error, 'no es tu turno');
        expect(sessionState.state, running);
      },
    );

    test('una acción válida limpia el error anterior', () {
      final s1 = _state();
      final s2 = _state();
      var shouldFail = true;
      gateway.onStart = (_, __) => s1;
      gateway.onApply = (_) {
        if (shouldFail) {
          shouldFail = false;
          throw const InvalidActionException('boom');
        }
        return s2;
      };

      final notifier = container.read(gameProvider.notifier);
      notifier.startLocalGame(const [], const GameConfig(playerCount: 2));
      notifier.drawCard('p1');
      expect((container.read(gameProvider) as GameRunning).error, 'boom');

      notifier.drawCard('p1');
      final sessionState = container.read(gameProvider) as GameRunning;
      expect(sessionState.error, isNull);
      expect(sessionState.state, s2);
    });

    test('ignora acciones si todavía no hay partida (GameIdle)', () {
      container.read(gameProvider.notifier).drawCard('p1');
      expect(container.read(gameProvider), isA<GameIdle>());
      expect(gateway.applyCalls, 0);
    });

    test('un GameState finalizado pasa a GameFinished', () {
      const result = GameResult(
        winnerId: 'p1',
        winnerName: 'A',
        totalTurns: 3,
        eliminationOrder: ['p2'],
      );
      gateway.onStart =
          (_, __) => _state(gamePhase: GamePhase.finished, result: result);

      container.read(gameProvider.notifier).startLocalGame(
        const [],
        const GameConfig(playerCount: 2),
      );

      final sessionState = container.read(gameProvider);
      expect(sessionState, isA<GameFinished>());
      expect((sessionState as GameFinished).result, result);
    });

    test(
      'agenda resolveNopeWindow cuando el turno entra en nopeWindow',
      () async {
        final nopeState = _state(phase: TurnPhase.nopeWindow);
        final resolvedState = _state(phase: TurnPhase.playing);
        gateway.onStart = (_, __) => nopeState;
        gateway.onResolve = () => resolvedState;

        container.read(gameProvider.notifier).startLocalGame(
          const [],
          const GameConfig(playerCount: 2),
        );

        expect(
          (container.read(gameProvider) as GameRunning).state.turn.phase,
          TurnPhase.nopeWindow,
        );

        await Future.delayed(const Duration(milliseconds: 30));

        expect(gateway.resolveCalls, 1);
        expect(
          (container.read(gameProvider) as GameRunning).state,
          resolvedState,
        );
      },
    );
  });
}
