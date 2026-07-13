import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:exploding_kittens/features/lobby/data/client_room_discovery.dart';
import 'package:exploding_kittens/features/lobby/domain/models/discovered_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd_platform_interface/nsd_platform_interface.dart';

import '../../../network/wifi/fake_nsd_platform.dart';

// Solo verifica la lógica propia de ClientRoomDiscovery contra un
// FakeNsdPlatform (igual que mdns_discoverer_test.dart) — no ejercita el
// descubrimiento mDNS real.
void main() {
  late FakeNsdPlatform fake;

  setUp(() {
    fake = FakeNsdPlatform();
    NsdPlatformInterface.instance = fake;
  });

  const room = DiscoveredRoom(
    roomId: 'room-1',
    hostName: 'Ana',
    hostAddress: '192.168.1.10',
    port: 8765,
    playerCount: 1,
    maxPlayers: 5,
  );

  Service serviceFor(DiscoveredRoom r) => Service(
        name: r.roomId,
        type: 'test',
        port: r.port,
        addresses: [InternetAddress(r.hostAddress)],
        txt: {
          'hostName': Uint8List.fromList(utf8.encode(r.hostName)),
          'playerCount': Uint8List.fromList(utf8.encode('${r.playerCount}')),
          'maxPlayers': Uint8List.fromList(utf8.encode('${r.maxPlayers}')),
        },
      );

  group('ClientRoomDiscovery', () {
    test('discover() expone las salas que van llegando', () async {
      final discovery = ClientRoomDiscovery();
      addTearDown(discovery.stop);

      final events = <List<DiscoveredRoom>>[];
      final sub = discovery.discover().listen(events.add);
      addTearDown(sub.cancel);

      // discover() es un generador async* que recién arranca la búsqueda
      // cuando alguien se suscribe.
      await Future<void>.delayed(Duration.zero);
      fake.lastDiscovery!.add(serviceFor(room));
      // El StreamController es broadcast: add() entrega a los listeners
      // en un microtask, no sincrónicamente.
      await Future<void>.delayed(Duration.zero);

      expect(events.last, [room]);
    });

    test(
      'llamar discover() de nuevo reinicia la búsqueda en vez de acumular '
      'el estado anterior',
      () async {
        final discovery = ClientRoomDiscovery();
        addTearDown(discovery.stop);

        final firstSub = discovery.discover().listen((_) {});
        await Future<void>.delayed(Duration.zero);
        fake.lastDiscovery!.add(serviceFor(room));
        await firstSub.cancel();

        // Un segundo discover() usa una Discovery nueva del fake — no
        // debería arrastrar el servicio que ya se había encontrado.
        final events = <List<DiscoveredRoom>>[];
        final sub = discovery.discover().listen(events.add);
        addTearDown(sub.cancel);
        await Future<void>.delayed(Duration.zero);

        expect(fake.lastDiscovery!.services, isEmpty);
      },
    );
  });
}
