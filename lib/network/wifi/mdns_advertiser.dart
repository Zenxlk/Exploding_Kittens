import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart';

import 'package:exploding_kittens/core/constants/app_constants.dart';

// Anuncia una sala en la red local vía mDNS/DNS-SD real (Bonjour en
// Apple, NsdManager en Android), usando el paquete `nsd`.
//
// NO VERIFICADO EN UN DISPOSITIVO REAL TODAVÍA. El paquete `nsd` es
// enteramente nativo (sin implementación en Dart puro), así que no hay
// forma de ejercitarlo end-to-end desde este entorno de desarrollo — los
// tests de esta clase mockean NsdPlatformInterface para probar la lógica
// propia (mapeo de campos, ciclo de vida), no el registro/descubrimiento
// mDNS real. Antes de confiar en esto hace falta la misma verificación
// manual en dispositivo que se hizo para Fase 5 (ver docs/VERIFICATION_LOG.md).
class MdnsAdvertiser {
  Registration? _registration;
  bool get isRunning => _registration != null;

  Future<void> start({
    required String roomId,
    required String hostName,
    required int playerCount,
    required int maxPlayers,
    int port = AppConstants.localGamePort,
  }) async {
    _registration = await register(
      Service(
        name: roomId,
        type: AppConstants.mdnsServiceType,
        port: port,
        txt: _txtFor(
          hostName: hostName,
          playerCount: playerCount,
          maxPlayers: maxPlayers,
        ),
      ),
    );
  }

  // El paquete `nsd` no permite actualizar los TXT records de un registro
  // ya activo — hay que des-registrar y volver a registrar. Es más costoso
  // que simplemente mandar otro beacon UDP (como hacía la versión anterior
  // basada en broadcast), pero en la práctica sigue siendo rápido: roomId
  // no cambia entre llamadas, así que no hay colisión de nombre que el
  // lado nativo tenga que resolver con reintentos.
  Future<void> updatePlayerCount({
    required int playerCount,
    required int maxPlayers,
  }) async {
    final current = _registration;
    if (current == null) return;

    final hostName = _decodeTxt(current.service.txt?['hostName']) ?? '';
    await unregister(current);
    _registration = await register(
      Service(
        name: current.service.name,
        type: current.service.type,
        port: current.service.port,
        txt: _txtFor(
          hostName: hostName,
          playerCount: playerCount,
          maxPlayers: maxPlayers,
        ),
      ),
    );
  }

  void stop() {
    final current = _registration;
    _registration = null;
    if (current != null) unregister(current);
  }

  static Map<String, Uint8List> _txtFor({
    required String hostName,
    required int playerCount,
    required int maxPlayers,
  }) =>
      {
        'hostName': Uint8List.fromList(utf8.encode(hostName)),
        'playerCount': Uint8List.fromList(utf8.encode('$playerCount')),
        'maxPlayers': Uint8List.fromList(utf8.encode('$maxPlayers')),
      };

  static String? _decodeTxt(Uint8List? bytes) =>
      bytes == null ? null : utf8.decode(bytes);
}
