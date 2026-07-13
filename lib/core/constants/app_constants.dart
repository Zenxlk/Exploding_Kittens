abstract final class AppConstants {
  static const String appName = 'Exploding Kittens';
  static const String company = 'ZenXLK';

  // WebSocket port for local WiFi games
  static const int localGamePort = 8765;

  // mDNS/DNS-SD service type registered/discovered by MdnsAdvertiser /
  // MdnsDiscoverer (via the nsd package)
  static const String mdnsServiceType = '_explkittens._tcp';

  static const Duration splashDuration = Duration(seconds: 2);
}
