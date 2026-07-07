abstract final class AppConstants {
  static const String appName = 'Exploding Kittens';
  static const String company = 'ZenXLK';

  // WebSocket port for local WiFi games
  static const int localGamePort = 8765;

  // UDP broadcast port used by MdnsAdvertiser / MdnsDiscoverer
  static const int discoveryPort = 8766;

  // mDNS service type — used for future proper mDNS registration
  static const String mdnsServiceType = '_explkittens._tcp';

  static const Duration splashDuration = Duration(seconds: 2);
}
