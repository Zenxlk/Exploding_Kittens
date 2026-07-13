import 'dart:async';
import 'dart:convert';

import 'package:exploding_kittens/features/lobby/data/host_beacon_sync.dart';
import 'package:exploding_kittens/features/lobby/domain/models/lobby_player.dart';
import 'package:exploding_kittens/features/lobby/domain/models/lobby_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd_platform_interface/nsd_platform_interface.dart';

import '../../../network/wifi/fake_nsd_platform.dart';

// Solo verifica la lógica propia de HostBeaconSync contra un
// FakeNsdPlatform (igual que mdns_advertiser_test.dart) — no ejercita el
// registro mDNS real.
void main() {
  late FakeNsdPlatform fake;

  setUp(() {
    fake = FakeNsdPlatform();
    NsdPlatformInterface.instance = fake;
  });

  const host = LobbyPlayer(id: 'h1', name: 'Ana', isHost: true);
  const p2 = LobbyPlayer(id: 'p2', name: 'Beto');

  group('HostBeaconSync', () {
    test('start registra el servicio con los datos iniciales', () async {
      final sync = HostBeaconSync();
      addTearDown(sync.stop);

      await sync.start(
        roomId: 'room-1',
        hostName: 'Ana',
        playerCount: 1,
        maxPlayers: 5,
        roomUpdates: const Stream.empty(),
      );

      expect(fake.registrations, hasLength(1));
      final service = fake.registrations.single.service;
      expect(service.name, 'room-1');
      expect(utf8.decode(service.txt!['playerCount']!), '1');
    });

    test(
      'reenvía cada cambio de sala como una actualización del conteo de '
      'jugadores',
      () async {
        final roomUpdates = StreamController<LobbyRoom>();
        final sync = HostBeaconSync();
        addTearDown(sync.stop);
        addTearDown(roomUpdates.close);

        await sync.start(
          roomId: 'room-1',
          hostName: 'Ana',
          playerCount: 1,
          maxPlayers: 5,
          roomUpdates: roomUpdates.stream,
        );

        roomUpdates.add(
          const LobbyRoom(id: 'room-1', hostId: 'h1', players: [host, p2]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(fake.registrations, hasLength(2));
        expect(
          utf8.decode(fake.registrations.last.service.txt!['playerCount']!),
          '2',
        );
      },
    );

    test('stop() deja de reenviar cambios de sala', () async {
      final roomUpdates = StreamController<LobbyRoom>();
      final sync = HostBeaconSync();
      addTearDown(roomUpdates.close);

      await sync.start(
        roomId: 'room-1',
        hostName: 'Ana',
        playerCount: 1,
        maxPlayers: 5,
        roomUpdates: roomUpdates.stream,
      );
      await sync.stop();

      roomUpdates.add(
        const LobbyRoom(id: 'room-1', hostId: 'h1', players: [host, p2]),
      );
      await Future<void>.delayed(Duration.zero);

      // Solo el registro inicial de start(); nada más se registró tras stop().
      expect(fake.registrations, hasLength(1));
    });
  });
}
