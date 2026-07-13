import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart';

import 'package:exploding_kittens/core/constants/app_constants.dart';
import 'package:exploding_kittens/features/lobby/domain/models/discovered_room.dart';

// Descubre salas en la red local vía mDNS/DNS-SD real (Bonjour en Apple,
// NsdManager en Android), usando el paquete `nsd`.
//
// NO VERIFICADO EN UN DISPOSITIVO REAL TODAVÍA — ver la nota en
// MdnsAdvertiser, aplica igual acá. A diferencia de la versión anterior
// basada en UDP broadcast, no hace falta podar salas manualmente: el
// propio NsdManager/Bonjour notifica ServiceStatus.lost cuando una sala
// deja de anunciarse, así que ya no hace falta un `staleAfter` propio.
class MdnsDiscoverer {
  Discovery? _discovery;
  final _roomsController = StreamController<List<DiscoveredRoom>>.broadcast();

  // Emite la lista actual cada vez que se encuentra o se pierde una sala.
  Stream<List<DiscoveredRoom>> get rooms => _roomsController.stream;

  Future<void> start({
    String serviceType = AppConstants.mdnsServiceType,
  }) async {
    final discovery = await startDiscovery(serviceType);
    discovery.addServiceListener(_onServiceEvent);
    _discovery = discovery;
    _emit();
  }

  void _onServiceEvent(Service service, ServiceStatus status) => _emit();

  void _emit() {
    final discovery = _discovery;
    if (discovery == null || _roomsController.isClosed) return;

    final rooms = discovery.services
        .map(_toDiscoveredRoom)
        .whereType<DiscoveredRoom>()
        .toList();
    _roomsController.add(rooms);
  }

  DiscoveredRoom? _toDiscoveredRoom(Service service) {
    final roomId = service.name;
    final hostAddress = service.addresses?.firstOrNull?.address;
    final port = service.port;
    if (roomId == null || hostAddress == null || port == null) return null;

    final txt = service.txt ?? const {};
    return DiscoveredRoom(
      roomId: roomId,
      hostName: _decodeTxt(txt['hostName']) ?? roomId,
      hostAddress: hostAddress,
      port: port,
      playerCount: int.tryParse(_decodeTxt(txt['playerCount']) ?? '') ?? 0,
      maxPlayers: int.tryParse(_decodeTxt(txt['maxPlayers']) ?? '') ?? 0,
    );
  }

  static String? _decodeTxt(Uint8List? bytes) =>
      bytes == null ? null : utf8.decode(bytes);

  Future<void> stop() async {
    final discovery = _discovery;
    _discovery = null;
    if (discovery != null) {
      discovery.removeServiceListener(_onServiceEvent);
      await stopDiscovery(discovery);
    }
    await _roomsController.close();
  }
}
