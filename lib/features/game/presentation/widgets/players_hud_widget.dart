import 'package:flutter/material.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/player/player_status.dart';

/// Fila de avatares de todos los jugadores (o de los oponentes, según lo que
/// le pase el caller) con su contador de cartas y quién tiene el turno.
/// Widget "tonto".
class PlayersHudWidget extends StatelessWidget {
  const PlayersHudWidget({
    super.key,
    required this.players,
    required this.currentPlayerId,
  });

  final List<PlayerModel> players;
  final String currentPlayerId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final player = players[index];
          return _PlayerBadge(
            player: player,
            isCurrentTurn: player.id == currentPlayerId,
          );
        },
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({required this.player, required this.isCurrentTurn});

  final PlayerModel player;
  final bool isCurrentTurn;

  bool get _isEliminated => player.status == PlayerStatus.eliminated;

  @override
  Widget build(BuildContext context) {
    final opacity = _isEliminated ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isCurrentTurn ? AppColors.primary : AppColors.surface,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, size: 12, color: AppColors.onBackground),
              const SizedBox(width: 2),
              Text('${player.cardCount}', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
