import 'package:equatable/equatable.dart';
import '../../../../core/constants/game_constants.dart';
import 'lobby_player.dart';
import 'lobby_status.dart';

class LobbyRoom extends Equatable {
  const LobbyRoom({
    required this.id,
    required this.hostId,
    required this.players,
    this.maxPlayers = GameConstants.maxPlayers,
    this.status = LobbyStatus.waiting,
  });

  final String id;
  final String hostId;
  final List<LobbyPlayer> players;
  final int maxPlayers;
  final LobbyStatus status;

  bool get isFull => players.length >= maxPlayers;
  bool get canStart =>
      players.length >= GameConstants.minPlayers &&
      players.every((p) => p.isReady || p.isHost);

  LobbyPlayer? get host =>
      players.where((p) => p.id == hostId).firstOrNull;

  LobbyRoom copyWith({
    List<LobbyPlayer>? players,
    LobbyStatus? status,
  }) {
    return LobbyRoom(
      id: id,
      hostId: hostId,
      players: players ?? this.players,
      maxPlayers: maxPlayers,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, hostId, players, maxPlayers, status];
}
