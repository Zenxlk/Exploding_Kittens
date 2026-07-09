import 'package:flutter/material.dart';

import 'package:exploding_kittens/game_engine/models/card/card_type.dart';

/// Apariencia de respaldo para cada [CardType] mientras no exista el arte
/// final de la carta. Usado por el placeholder cuando [CardAssetResolver]
/// no encuentra la imagen real en el asset bundle.
abstract final class CardVisuals {
  static (Color color, IconData icon, String label) of(CardType type) {
    return switch (type) {
      CardType.explodingKitten => (
          Colors.red.shade900,
          Icons.whatshot,
          'Exploding Kitten',
        ),
      CardType.defuse => (Colors.blue.shade700, Icons.security, 'Defuse'),
      CardType.nope => (Colors.grey.shade800, Icons.block, 'Nope'),
      CardType.attack => (Colors.orange.shade800, Icons.bolt, 'Attack'),
      CardType.skip => (Colors.teal.shade700, Icons.fast_forward, 'Skip'),
      CardType.favor => (
          Colors.purple.shade700,
          Icons.volunteer_activism,
          'Favor',
        ),
      CardType.shuffle => (Colors.indigo.shade700, Icons.shuffle, 'Shuffle'),
      CardType.seeTheFuture => (
          Colors.cyan.shade700,
          Icons.visibility,
          'See the Future',
        ),
      CardType.tacocat => (Colors.pink.shade400, Icons.pets, 'Tacocat'),
      CardType.rainbowRalphingCat => (
          Colors.deepPurple.shade300,
          Icons.pets,
          'Rainbow-Ralphing Cat',
        ),
      CardType.beardedDragon => (
          Colors.green.shade600,
          Icons.pets,
          'Bearded Dragon',
        ),
      CardType.cattermelon => (
          Colors.lightGreen.shade600,
          Icons.pets,
          'Cattermelon',
        ),
      CardType.hairyPotatoCat => (
          Colors.brown.shade400,
          Icons.pets,
          'Hairy Potato Cat',
        ),
    };
  }
}
