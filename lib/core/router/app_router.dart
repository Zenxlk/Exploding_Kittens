import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lobby/presentation/screens/lobby_screen.dart';
import '../../features/game/presentation/screens/game_screen.dart';
import '../../features/game/presentation/screens/game_over_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: RouteNames.createRoom,
      builder: (_, __) => const LobbyScreen(isHost: true),
    ),
    GoRoute(
      path: RouteNames.joinRoom,
      builder: (_, __) => const LobbyScreen(isHost: false),
    ),
    GoRoute(
      path: RouteNames.game,
      builder: (_, __) => const GameScreen(),
    ),
    GoRoute(
      path: RouteNames.gameOver,
      builder: (_, __) => const GameOverScreen(),
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
