import 'package:exploding_kittens/features/lobby/domain/models/discovered_room.dart';
import 'package:exploding_kittens/network/wifi/mdns_discoverer.dart';

/// Encapsula el ciclo de vida del `MdnsDiscoverer` del lado cliente: cada
/// llamada a [discover] reinicia la búsqueda desde cero. Extraído de
/// `LobbyRepository` para que la parte "solo cliente" no viva mezclada con
/// la parte "solo host" (`HostBeaconSync`) en la misma clase.
class ClientRoomDiscovery {
  MdnsDiscoverer? _discoverer;

  Stream<List<DiscoveredRoom>> discover() async* {
    await stop();
    _discoverer = MdnsDiscoverer();
    await _discoverer!.start();
    yield* _discoverer!.rooms;
  }

  Future<void> stop() async {
    await _discoverer?.stop();
    _discoverer = null;
  }
}
