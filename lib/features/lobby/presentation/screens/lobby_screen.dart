import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:exploding_kittens/core/router/route_names.dart';
import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';
import 'package:exploding_kittens/features/lobby/domain/models/discovered_room.dart';
import 'package:exploding_kittens/features/lobby/domain/models/lobby_player.dart';
import 'package:exploding_kittens/features/lobby/domain/models/lobby_room.dart';
import 'package:exploding_kittens/features/lobby/domain/models/lobby_status.dart';
import 'package:exploding_kittens/features/lobby/presentation/providers/lobby_providers.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.isHost});
  final bool isHost;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isHost) {
        ref.read(lobbyProvider.notifier).createRoom();
      } else {
        ref.read(lobbyProvider.notifier).startDiscovery();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LobbyState>(lobbyProvider, (_, next) {
      switch (next) {
        case LobbyInRoom(:final room) when room.status == LobbyStatus.starting:
          context.go(RouteNames.game);
        case LobbyError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.primary,
            ),
          );
          context.pop();
        default:
          break;
      }
    });

    final lobbyState = ref.watch(lobbyProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await ref.read(lobbyProvider.notifier).leaveRoom();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          title: Text(
            widget.isHost ? 'Create Room' : 'Join Room',
            style: AppTextStyles.title,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              await ref.read(lobbyProvider.notifier).leaveRoom();
              if (context.mounted) context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: switch (lobbyState) {
            LobbyIdle() || LobbyConnecting() => _ConnectingView(
                label: widget.isHost ? 'Creating room…' : 'Connecting…',
              ),
            LobbyDiscovering(:final rooms) => _DiscoveringView(
                rooms: rooms,
                onJoin: (r) =>
                    ref.read(lobbyProvider.notifier).joinRoom(r.hostAddress),
              ),
            LobbyInRoom() => _InRoomView(lobbyState),
            LobbyError() => _ConnectingView(label: 'Error…'),
          },
        ),
      ),
    );
  }
}

// ── Connecting splash ──────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const Gap(20),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ── Discovery view ─────────────────────────────────────────────────────────────

class _DiscoveringView extends StatelessWidget {
  const _DiscoveringView({
    required this.rooms,
    required this.onJoin,
  });

  final List<DiscoveredRoom> rooms;
  final void Function(DiscoveredRoom) onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              ),
              const Gap(10),
              Text(
                'Scanning local network…',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onBackground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_find_rounded,
                        size: 56,
                        color: AppColors.onBackground.withValues(alpha: 0.2),
                      ),
                      const Gap(12),
                      Text(
                        'No rooms found yet',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.onBackground.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) => _RoomCard(
                    room: rooms[i],
                    onTap: () => onJoin(rooms[i]),
                  ).animate().fadeIn(delay: (i * 60).ms).slideY(
                        begin: 0.2,
                        end: 0,
                        curve: Curves.easeOut,
                      ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextButton.icon(
            onPressed: () => _showManualIpDialog(context),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Enter IP manually'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onBackground.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  void _showManualIpDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Host IP address', style: AppTextStyles.title),
        content: TextField(
          controller: controller,
          style: AppTextStyles.body,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '192.168.1.x',
            hintStyle: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.4),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(
                color: AppColors.onBackground.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                onJoin(DiscoveredRoom(
                  roomId: 'manual',
                  hostName: ip,
                  hostAddress: ip,
                  port: 8765,
                  playerCount: 0,
                  maxPlayers: 5,
                ));
              }
            },
            child: Text(
              'Connect',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});
  final DiscoveredRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const Icon(
          Icons.meeting_room_rounded,
          color: AppColors.secondary,
          size: 28,
        ),
        title: Text(room.hostName, style: AppTextStyles.body),
        subtitle: Text(
          room.hostAddress,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onBackground.withValues(alpha: 0.45),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${room.playerCount}/${room.maxPlayers}',
              style: AppTextStyles.caption.copyWith(
                color: room.isFull
                    ? AppColors.eliminated
                    : AppColors.success,
              ),
            ),
            const Gap(8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onBackground.withValues(alpha: 0.3),
            ),
          ],
        ),
        onTap: room.isFull ? null : onTap,
      ),
    );
  }
}

// ── In-room view ──────────────────────────────────────────────────────────────

class _InRoomView extends ConsumerWidget {
  const _InRoomView(this.lobbyState);
  final LobbyInRoom lobbyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = lobbyState.room;
    final isHost = lobbyState.isHost;

    return Column(
      children: [
        // ── Room info header ────────────────────────────────────────────
        _RoomHeader(room: room, isHost: isHost),

        // ── Player list ─────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: room.players.length,
            itemBuilder: (_, i) => _PlayerTile(
              player: room.players[i],
              isLocalPlayer: room.players[i].id == lobbyState.localPlayerId,
            )
                .animate()
                .fadeIn(delay: (i * 50).ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ),

        // ── Action bar ──────────────────────────────────────────────────
        _ActionBar(lobbyState: lobbyState, ref: ref),
      ],
    );
  }
}

class _RoomHeader extends ConsumerWidget {
  const _RoomHeader({required this.room, required this.isHost});
  final LobbyRoom room;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiIp = ref.watch(wifiIpProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.players.length}/${room.maxPlayers} players',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1,
                  ),
                ),
                const Gap(2),
                if (isHost)
                  wifiIp.when(
                    data: (ip) => GestureDetector(
                      onTap: ip == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: ip));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('IP copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ip ?? 'No WiFi',
                            style: AppTextStyles.body.copyWith(
                              color: ip == null
                                  ? AppColors.eliminated
                                  : AppColors.onBackground,
                            ),
                          ),
                          if (ip != null) ...[
                            const Gap(6),
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppColors.onBackground
                                  .withValues(alpha: 0.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    loading: () => Text(
                      'Reading IP…',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onBackground.withValues(alpha: 0.4),
                      ),
                    ),
                    error: (_, __) => Text(
                      'WiFi IP unavailable',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.eliminated,
                      ),
                    ),
                  )
                else
                  Text(
                    'Waiting for host to start…',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          // Waiting dots animation
          if (room.players.length < room.maxPlayers)
            Row(
              children: List.generate(
                room.maxPlayers - room.players.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.onBackground.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.isLocalPlayer});
  final LobbyPlayer player;
  final bool isLocalPlayer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: player.isHost
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.surface,
        child: Text(
          player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color:
                player.isHost ? AppColors.primary : AppColors.onBackground,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            player.name + (isLocalPlayer ? ' (you)' : ''),
            style: AppTextStyles.body,
          ),
          if (player.isHost) ...[
            const Gap(6),
            Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
          ],
        ],
      ),
      trailing: player.isHost
          ? null
          : AnimatedSwitcher(
              duration: 300.ms,
              child: player.isReady
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      key: ValueKey('ready'),
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: AppColors.onBackground.withValues(alpha: 0.3),
                      key: const ValueKey('not_ready'),
                    ),
            ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.lobbyState, required this.ref});
  final LobbyInRoom lobbyState;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isHost = lobbyState.isHost;
    final room = lobbyState.room;

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: SizedBox(
        width: double.infinity,
        child: isHost
            ? ElevatedButton.icon(
                onPressed: room.canStart
                    ? () => ref.read(lobbyProvider.notifier).startGame()
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  room.canStart ? 'Start Game' : 'Waiting for players…',
                  style: AppTextStyles.body,
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => ref
                    .read(lobbyProvider.notifier)
                    .setReady(ready: !lobbyState.isLocalPlayerReady),
                icon: Icon(
                  lobbyState.isLocalPlayerReady
                      ? Icons.close_rounded
                      : Icons.check_rounded,
                ),
                label: Text(
                  lobbyState.isLocalPlayerReady ? 'Not Ready' : 'Ready',
                  style: AppTextStyles.body,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lobbyState.isLocalPlayerReady
                      ? AppColors.surface
                      : AppColors.success,
                  foregroundColor: lobbyState.isLocalPlayerReady
                      ? AppColors.onBackground.withValues(alpha: 0.7)
                      : Colors.white,
                ),
              ),
      ),
    );
  }
}
