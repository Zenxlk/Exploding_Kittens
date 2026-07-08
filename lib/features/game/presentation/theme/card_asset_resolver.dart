import 'package:flutter/services.dart';

import 'package:exploding_kittens/core/constants/asset_paths.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';

/// Resuelve la ruta de asset real de una carta si ya existe en el bundle,
/// o `null` si todavía no se ha añadido (fallback a placeholder).
///
/// Así se puede ir soltando el arte final carta por carta sin tocar ningún
/// widget: hoy con `assets/cards/` vacío todo resuelve a `null`, y en cuanto
/// aparezca `tacocat.png` esta clase empieza a devolverlo sin más cambios.
class CardAssetResolver {
  const CardAssetResolver(this._manifest);

  final AssetManifest _manifest;

  static Future<CardAssetResolver> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return CardAssetResolver(manifest);
  }

  String? cardBackAsset() =>
      _existsInManifest(AssetPaths.cardBack) ? AssetPaths.cardBack : null;

  String? faceAssetFor(CardType type) {
    final path = _pathFor(type);
    return _existsInManifest(path) ? path : null;
  }

  bool _existsInManifest(String path) => _manifest.listAssets().contains(path);

  static String _pathFor(CardType type) => switch (type) {
        CardType.explodingKitten => AssetPaths.explodingKitten,
        CardType.defuse => AssetPaths.defuse,
        CardType.nope => AssetPaths.nope,
        CardType.attack => AssetPaths.attack,
        CardType.skip => AssetPaths.skip,
        CardType.favor => AssetPaths.favor,
        CardType.shuffle => AssetPaths.shuffle,
        CardType.seeTheFuture => AssetPaths.seeTheFuture,
        CardType.tacocat => AssetPaths.tacocat,
        CardType.rainbowRalphingCat => AssetPaths.rainbowRalphingCat,
        CardType.beardedDragon => AssetPaths.beardedDragon,
        CardType.cattermelon => AssetPaths.cattermelon,
        CardType.hairyPotatoCat => AssetPaths.hairyPotatoCat,
      };
}
