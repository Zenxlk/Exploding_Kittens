import 'package:nsd_platform_interface/nsd_platform_interface.dart';

/// Fake de [NsdPlatformInterface] para testear la lógica propia de
/// MdnsAdvertiser/MdnsDiscoverer (mapeo de campos, ciclo de vida de
/// registro/descubrimiento) sin depender del lado nativo real — el
/// paquete `nsd` no tiene ninguna implementación en Dart puro, así que no
/// hay forma de ejercitar el registro/descubrimiento mDNS de verdad desde
/// `flutter test`. Esto NO reemplaza la verificación manual en un
/// dispositivo real.
class FakeNsdPlatform extends NsdPlatformInterface {
  final List<Registration> registrations = [];
  final List<Registration> unregistrations = [];
  Discovery? lastDiscovery;
  int _idCounter = 0;

  @override
  Future<Discovery> startDiscovery(
    String serviceType, {
    bool autoResolve = true,
    IpLookupType ipLookupType = IpLookupType.none,
  }) async {
    final discovery = Discovery('discovery-${_idCounter++}');
    lastDiscovery = discovery;
    return discovery;
  }

  @override
  Future<void> stopDiscovery(Discovery discovery) async {}

  @override
  Future<Service> resolve(Service service) async => service;

  @override
  Future<Registration> register(Service service) async {
    final registration = Registration('registration-${_idCounter++}', service);
    registrations.add(registration);
    return registration;
  }

  @override
  Future<void> unregister(Registration registration) async {
    unregistrations.add(registration);
  }

  @override
  void enableLogging(LogTopic logTopic) {}

  @override
  void disableServiceTypeValidation(bool value) {}
}
