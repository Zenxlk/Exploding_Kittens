import 'package:exploding_kittens/network/reconnection/reconnection_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReconnectionManager', () {
    late ReconnectionManager manager;

    setUp(() {
      manager = ReconnectionManager(
        graceTimeout: const Duration(milliseconds: 20),
      );
    });

    tearDown(() => manager.dispose());

    test('llama a onExpired si no se cancela antes del timeout', () async {
      String? expiredId;
      manager.trackDisconnect('p1', (id) => expiredId = id);

      expect(manager.isPending('p1'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(expiredId, 'p1');
      expect(manager.isPending('p1'), isFalse);
    });

    test('cancelIfPending evita que se llame a onExpired', () async {
      var called = false;
      manager.trackDisconnect('p1', (_) => called = true);

      manager.cancelIfPending('p1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(called, isFalse);
      expect(manager.isPending('p1'), isFalse);
    });

    test('cancelIfPending sin timer pendiente no hace nada', () {
      expect(() => manager.cancelIfPending('nadie'), returnsNormally);
    });

    test('trackDisconnect reinicia el timeout si se llama dos veces', () async {
      var callCount = 0;
      manager.trackDisconnect('p1', (_) => callCount++);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      manager.trackDisconnect('p1', (_) => callCount++);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(callCount, 0); // el segundo track reinició el reloj

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(callCount, 1);
    });

    test('rastrea a varios jugadores de forma independiente', () async {
      final expired = <String>[];
      manager.trackDisconnect('p1', expired.add);
      manager.trackDisconnect('p2', expired.add);
      manager.cancelIfPending('p2');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(expired, ['p1']);
    });

    test('dispose cancela todos los timers pendientes', () async {
      var called = false;
      manager.trackDisconnect('p1', (_) => called = true);
      manager.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(called, isFalse);
    });
  });
}
