import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:exploding_kittens/features/lobby/domain/models/discovered_room.dart';
import 'package:exploding_kittens/network/wifi/mdns_discoverer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd_platform_interface/nsd_platform_interface.dart';

import 'fake_nsd_platform.dart';

// Igual que mdns_advertiser_test.dart: solo verifica la lógica propia de
// MdnsDiscoverer contra un FakeNsdPlatform, simulando eventos de servicio
// llamando directamente Discovery.add()/remove() (públicos en el paquete,
// aunque marcados "TODO hide this" ahí). No ejercita el descubrimiento
// mDNS real — falta verificación manual en un dispositivo real.
Service _serviceFor(
  DiscoveredRoom room,
) =>
    Service(
      name: room.roomId,
      type: 'test',
      port: room.port,
      addresses: [InternetAddress(room.hostAddress)],
      txt: {
        'hostName': Uint8List.fromList(utf8.encode(room.hostName)),
        'playerCount': Uint8List.fromList(
          utf8.encode('${room.playerCount}'),
        ),
        'maxPlayers': Uint8List.fromList(utf8.encode('${room.maxPlayers}')),
      },
    );

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

  group('MdnsDiscoverer', () {
    test('un servicio encontrado aparece en rooms', () async {
      final discoverer = MdnsDiscoverer();
      addTearDown(discoverer.stop);

      final events = <List<DiscoveredRoom>>[];
      final sub = discoverer.rooms.listen(events.add);
      addTearDown(sub.cancel);

      await discoverer.start();
      fake.lastDiscovery!.add(_serviceFor(room));
      // El StreamController es broadcast: add() entrega a los listeners
      // en un microtask, no sincrónicamente.
      await Future<void>.delayed(Duration.zero);

      expect(events.last, [room]);
    });

    test('un servicio perdido se elimina de rooms', () async {
      final discoverer = MdnsDiscoverer();
      addTearDown(discoverer.stop);

      final events = <List<DiscoveredRoom>>[];
      final sub = discoverer.rooms.listen(events.add);
      addTearDown(sub.cancel);

      await discoverer.start();
      final service = _serviceFor(room);
      fake.lastDiscovery!.add(service);
      await Future<void>.delayed(Duration.zero);
      expect(events.last, [room]);

      fake.lastDiscovery!.remove(service);
      await Future<void>.delayed(Duration.zero);
      expect(events.last, isEmpty);
    });

    test(
      'un Service sin dirección resuelta o sin puerto se ignora',
      () async {
        final discoverer = MdnsDiscoverer();
        addTearDown(discoverer.stop);

        final events = <List<DiscoveredRoom>>[];
        final sub = discoverer.rooms.listen(events.add);
        addTearDown(sub.cancel);

        await discoverer.start();
        fake.lastDiscovery!.add(
          const Service(name: 'room-2', type: 'test'), // sin address ni port
        );
        await Future<void>.delayed(Duration.zero);

        expect(events.last, isEmpty);
      },
    );

    test('stop() cierra el stream de rooms', () async {
      final discoverer = MdnsDiscoverer();
      await discoverer.start();

      await discoverer.stop();

      await expectLater(discoverer.rooms, emitsDone);
    });
  });
}
