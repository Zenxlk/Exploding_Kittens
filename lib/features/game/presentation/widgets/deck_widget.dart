import 'package:flutter/material.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';

/// Mazo de robo: dorso + contador de cartas restantes. Widget "tonto",
/// no lee providers.
class DeckWidget extends StatelessWidget {
  const DeckWidget({
    super.key,
    required this.drawPileCount,
    this.cardBackAssetPath,
    this.width = 72,
    this.onTap,
  });

  final int drawPileCount;
  final String? cardBackAssetPath;
  final double width;
  final VoidCallback? onTap;

  double get _height => width * 1.4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: _height,
            decoration: BoxDecoration(
              color: AppColors.cardBack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black38),
            ),
            child: cardBackAssetPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(cardBackAssetPath!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Icon(
                      Icons.style,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: width * 0.4,
                    ),
                  ),
          ),
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.onBackground, width: 1),
              ),
              child: Text('$drawPileCount', style: AppTextStyles.caption),
            ),
          ),
        ],
      ),
    );
  }
}
