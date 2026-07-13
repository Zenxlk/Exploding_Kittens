import 'dart:convert';

import 'package:exploding_kittens/network/wifi/mdns_advertiser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd_platform_interface/nsd_platform_interface.dart';

import 'fake_nsd_platform.dart';

// Estos tests solo verifican la lógica propia de MdnsAdvertiser (qué
// Service arma, cómo maneja el ciclo de vida de la registración) contra un
// FakeNsdPlatform — no ejercitan el registro mDNS real, que es enteramente
// nativo. Ver la nota en mdns_advertiser.dart: falta verificación manual
// en un dispositivo real antes de confiar en esto.
void main() {
  late FakeNsdPlatform fake;

  setUp(() {
    fake = FakeNsdPlatform();
    NsdPlatformInterface.instance = fake;
  });

  group('MdnsAdvertiser', () {
    test('start registra un Service con los datos de la sala', () async {
      final advertiser = MdnsAdvertiser();

      await advertiser.start(
        roomId: 'room-1',
        hostName: 'Ana',
        playerCount: 1,
        maxPlayers: 5,
        port: 8765,
      );

      expect(fake.registrations, hasLength(1));
      final service = fake.registrations.single.service;
      expect(service.name, 'room-1');
      expect(service.port, 8765);
      expect(utf8.decode(service.txt!['hostName']!), 'Ana');
      expect(utf8.decode(service.txt!['playerCount']!), '1');
      expect(utf8.decode(service.txt!['maxPlayers']!), '5');
      expect(advertiser.isRunning, isTrue);
    });

    test(
      'updatePlayerCount des-registra y vuelve a registrar con el conteo '
      'nuevo',
      () async {
        final advertiser = MdnsAdvertiser();
        await advertiser.start(
          roomId: 'room-1',
          hostName: 'Ana',
          playerCount: 1,
          maxPlayers: 5,
        );

        await advertiser.updatePlayerCount(playerCount: 3, maxPlayers: 5);

        expect(fake.unregistrations, hasLength(1));
        expect(fake.registrations, hasLength(2));
        final updated = fake.registrations.last.service;
        expect(updated.name, 'room-1');
        expect(utf8.decode(updated.txt!['hostName']!), 'Ana');
        expect(utf8.decode(updated.txt!['playerCount']!), '3');
      },
    );

    test('updatePlayerCount antes de start() no hace nada', () async {
      final advertiser = MdnsAdvertiser();

      await advertiser.updatePlayerCount(playerCount: 3, maxPlayers: 5);

      expect(fake.registrations, isEmpty);
      expect(fake.unregistrations, isEmpty);
    });

    test('stop des-registra el servicio activo', () async {
      final advertiser = MdnsAdvertiser();
      await advertiser.start(
        roomId: 'room-1',
        hostName: 'Ana',
        playerCount: 1,
        maxPlayers: 5,
      );

      advertiser.stop();
      // unregister() es async; deja correr un microtask para que se procese.
      await Future<void>.delayed(Duration.zero);

      expect(fake.unregistrations, hasLength(1));
      expect(advertiser.isRunning, isFalse);
    });
  });
}
