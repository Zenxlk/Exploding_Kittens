import 'package:exploding_kittens/app.dart';
import 'package:exploding_kittens/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — arranca sin errores', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App()),
    );

    // Verify MaterialApp renders on the first frame (SplashScreen).
    expect(find.byType(MaterialApp), findsOneWidget);

    // Advance past the SplashScreen timer so it fires and disposes cleanly,
    // then drain animations (flutter_animate) before the test exits.
    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();
  });
}
