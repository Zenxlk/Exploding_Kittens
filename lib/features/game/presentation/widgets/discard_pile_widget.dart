import 'package:flutter/material.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/features/game/presentation/widgets/card_widget.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';

/// Pila de descarte: muestra la última carta jugada boca arriba, o un hueco
/// vacío si todavía no se ha descartado nada. Widget "tonto".
class DiscardPileWidget extends StatelessWidget {
  const DiscardPileWidget({
    super.key,
    required this.topCard,
    this.topCardAssetPath,
    this.width = 72,
  });

  final CardModel? topCard;
  final String? topCardAssetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    final card = topCard;
    if (card == null) {
      return DottedCardSlot(width: width);
    }
    return CardWidget(
        type: card.type, assetPath: topCardAssetPath, width: width);
  }
}

/// Hueco vacío con borde punteado-simulado (sin depender de un paquete
/// externo) para la pila de descarte o cualquier otro slot sin carta.
class DottedCardSlot extends StatelessWidget {
  const DottedCardSlot({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.onBackground.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }
}
