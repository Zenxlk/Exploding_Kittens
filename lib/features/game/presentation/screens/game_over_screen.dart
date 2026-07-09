import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:exploding_kittens/core/router/route_names.dart';
import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';
import 'package:exploding_kittens/features/game/presentation/providers/game_providers.dart';
import 'package:exploding_kittens/features/lobby/presentation/providers/lobby_providers.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';

/// Resultado de la partida: ganador, ranking por orden real de eliminación
/// (último eliminado queda 2º, el primero en explotar queda último) y
/// revancha. Solo el host puede iniciarla hoy — mismo límite que
/// `GameScreen`: solo el host corre el `GameEngine` real hasta que la Fase 5
/// sincronice el estado por red.
class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(gameProvider);
    final lobbyState = ref.watch(lobbyProvider);

    if (sessionState is! GameFinished) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _CenteredColumn(
          children: [
            Text(
              'No hay ningún resultado de partida',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Volver al menú'),
            ),
          ],
        ),
      );
    }

    final result = sessionState.result;
    final inRoom = lobbyState is LobbyInRoom ? lobbyState : null;
    final players = inRoom?.room.players ?? const [];
    String nameFor(String id) =>
        players.where((p) => p.id == id).firstOrNull?.name ?? id;

    final ranking = [result.winnerId, ...result.eliminationOrder.reversed];
    final isHost = inRoom?.isHost ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _CenteredColumn(
          children: [
            Text(
              '¡${result.winnerName} ganó!',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${result.totalTurns} turnos jugados',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < ranking.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${i + 1}. ${nameFor(ranking[i])}',
                  style: AppTextStyles.body,
                ),
              ),
            const SizedBox(height: 32),
            if (isHost)
              FilledButton(
                onPressed: () => _rematch(context, ref, inRoom!),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Revancha'),
              )
            else
              Text(
                'Esperando a que el host inicie una revancha…',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Volver al menú'),
            ),
          ],
        ),
      ),
    );
  }

  void _rematch(BuildContext context, WidgetRef ref, LobbyInRoom lobbyState) {
    final players = lobbyState.room.players
        .map((p) => PlayerModel(id: p.id, name: p.name, hand: const []))
        .toList();
    ref
        .read(gameProvider.notifier)
        .startLocalGame(players, GameConfig(playerCount: players.length));
    context.go(RouteNames.game);
  }
}

class _CenteredColumn extends StatelessWidget {
  const _CenteredColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
