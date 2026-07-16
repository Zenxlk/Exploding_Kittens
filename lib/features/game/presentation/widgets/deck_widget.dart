import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';

/// Mazo de robo: dorso + contador de cartas restantes. Widget "tonto",
/// no lee providers ni streams — [shuffleTrigger]/[pulseTrigger] son
/// simples contadores que el caller incrementa (p. ej. al recibir un
/// `DeckShuffledEvent`/`CardDrawnEvent`); solo reaccionan al cambio, igual
/// que `NopeWindowOverlay` con `nopeChainCount`. Efectos distintos a
/// propósito (bamboleo largo vs. pulso corto) para que se puedan
/// distinguir mezclar de robar.
class DeckWidget extends StatefulWidget {
  const DeckWidget({
    super.key,
    required this.drawPileCount,
    this.cardBackAssetPath,
    this.width = 72,
    this.onTap,
    this.shuffleTrigger = 0,
    this.pulseTrigger = 0,
  });

  final int drawPileCount;
  final String? cardBackAssetPath;
  final double width;
  final VoidCallback? onTap;
  final int shuffleTrigger;
  final int pulseTrigger;

  @override
  State<DeckWidget> createState() => _DeckWidgetState();
}

class _DeckWidgetState extends State<DeckWidget> with TickerProviderStateMixin {
  late final AnimationController _shuffleController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didUpdateWidget(covariant DeckWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shuffleTrigger != widget.shuffleTrigger) {
      _shuffleController.forward(from: 0);
    }
    if (oldWidget.pulseTrigger != widget.pulseTrigger) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double get _height => widget.width * 1.4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shuffleController, _pulseController]),
        builder: (context, child) {
          // Bamboleo que se amortigua a medida que avanza la animación, para
          // que se sienta como una mezcla rápida en vez de un giro continuo.
          final t = _shuffleController.value;
          final wobble = math.sin(t * math.pi * 6) * (1 - t) * 0.12;
          // Pulso corto y seco (achica y vuelve), distinto del bamboleo.
          final p = _pulseController.value;
          final scale = 1 - math.sin(p * math.pi) * 0.08;
          return Transform.rotate(
            angle: wobble,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.width,
              height: _height,
              decoration: BoxDecoration(
                color: AppColors.cardBack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black38),
              ),
              child: widget.cardBackAssetPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(widget.cardBackAssetPath!,
                          fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(
                        Icons.style,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: widget.width * 0.4,
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
                child: Text('${widget.drawPileCount}',
                    style: AppTextStyles.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
