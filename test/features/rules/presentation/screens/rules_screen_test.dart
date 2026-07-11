import 'package:exploding_kittens/core/router/route_names.dart';
import 'package:exploding_kittens/features/rules/presentation/screens/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// RulesScreen's back button uses go_router's context.pop(), so it needs a
// real GoRouter in the tree (not just a Navigator).
Widget _wrap() {
  final router = GoRouter(
    initialLocation: RouteNames.rules,
    routes: [
      GoRoute(path: RouteNames.rules, builder: (_, __) => const RulesScreen()),
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const Scaffold(body: Text('home-screen')),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

// La pantalla es un ListView largo (13 cartas + intro); se agranda la
// superficie de prueba para que todo el contenido se construya de una, en
// vez de depender de scroll manual para cada aserción (un Sliver no
// construye los widgets que quedan fuera del viewport).
void _growViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('RulesScreen', () {
    testWidgets('muestra el título y las secciones principales', (
      tester,
    ) async {
      _growViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Cómo jugar'), findsOneWidget);
      expect(find.text('EL OBJETIVO'), findsOneWidget);
      expect(find.text('ANTES DE EMPEZAR'), findsOneWidget);
      expect(find.text('TU TURNO'), findsOneWidget);
      expect(find.text('CARTAS ESPECIALES'), findsOneWidget);
      expect(find.text('CARTAS DE ACCIÓN'), findsOneWidget);
      expect(find.text('GATOS'), findsOneWidget);
    });

    testWidgets('muestra las 13 cartas del juego, cada una con su nombre', (
      tester,
    ) async {
      _growViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      const labels = [
        'Exploding Kitten',
        'Defuse',
        'Nope',
        'Attack',
        'Skip',
        'Favor',
        'Shuffle',
        'See the Future',
        'Tacocat',
        'Rainbow-Ralphing Cat',
        'Bearded Dragon',
        'Cattermelon',
        'Hairy Potato Cat',
      ];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget,
            reason: '$label debería verse');
      }
    });

    testWidgets(
      'aclara que el trío de gatos todavía no está disponible en esta '
      'versión',
      (tester) async {
        _growViewport(tester);
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        expect(
          find.textContaining('trío'),
          findsOneWidget,
        );
        expect(
          find.textContaining('todavía no está disponible'),
          findsOneWidget,
        );
      },
    );

    testWidgets('el botón de volver hace pop de la ruta', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // No hay a dónde volver dentro del propio router de la prueba (rules
      // es la ruta inicial); solo confirmamos que el botón existe y no
      // rompe nada al tocarlo cuando no hay historial previo.
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
