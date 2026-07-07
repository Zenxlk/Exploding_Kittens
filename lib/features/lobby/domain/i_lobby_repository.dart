import '../../../core/errors/failures.dart';
import 'models/lobby_player.dart';
import 'models/lobby_room.dart';

abstract interface class ILobbyRepository {
  // Stream con el estado en tiempo real de la sala actual
  Stream<LobbyRoom> get roomStream;

  // Host crea una sala nueva y devuelve su estado inicial
  Future<Result<LobbyRoom>> createRoom({
    required String playerName,
    required String playerId,
  });

  // Cliente escanea la red y devuelve salas disponibles vía mDNS
  Stream<List<LobbyPlayer>> discoverRooms();

  // Cliente se une a una sala existente
  Future<Result<LobbyRoom>> joinRoom({
    required String hostAddress,
    required String playerName,
    required String playerId,
  });

  // Marca al jugador local como listo / no listo
  Future<Result<void>> setReady({required bool ready});

  // Host inicia la partida (solo válido si canStart == true)
  Future<Result<void>> startGame();

  // Abandona la sala (cierra el servidor si es host)
  Future<void> leaveRoom();
}
