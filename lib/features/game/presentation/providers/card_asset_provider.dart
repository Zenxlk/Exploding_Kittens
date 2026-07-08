import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:exploding_kittens/features/game/presentation/theme/card_asset_resolver.dart';

/// Se carga una sola vez por sesión de la app; en los widgets, usar
/// `ref.watch(cardAssetResolverProvider).valueOrNull` con fallback a
/// placeholder mientras está en `loading` o `error`.
final cardAssetResolverProvider = FutureProvider<CardAssetResolver>(
  (_) => CardAssetResolver.load(),
);
