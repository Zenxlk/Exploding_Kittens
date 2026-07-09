import 'package:flutter/material.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';

/// Selector de posición para reinsertar la Exploding Kitten al jugar Defuse.
/// Widget "tonto": el motor acepta cualquier posición entre 0 (arriba del
/// todo, la próxima carta robada) y [drawPileCount] (abajo del todo) — ver
/// `DeckManager.insertAt`, que además clampa por seguridad.
class InsertBombOverlay extends StatefulWidget {
  const InsertBombOverlay({
    super.key,
    required this.drawPileCount,
    required this.onConfirm,
  });

  final int drawPileCount;
  final ValueChanged<int> onConfirm;

  @override
  State<InsertBombOverlay> createState() => _InsertBombOverlayState();
}

class _InsertBombOverlayState extends State<InsertBombOverlay> {
  late int _position = widget.drawPileCount;

  @override
  Widget build(BuildContext context) {
    final maxPosition = widget.drawPileCount;
    final description = switch (_position) {
      0 => 'Arriba del todo — la próxima carta que se robe',
      _ when _position == maxPosition => 'Abajo del todo',
      _ => 'A $_position carta(s) de la de arriba',
    };

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Dónde escondes la bomba?', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              width: 260,
              child: Slider(
                value: _position.toDouble(),
                min: 0,
                max: maxPosition.toDouble(),
                divisions: maxPosition == 0 ? null : maxPosition,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _position = v.round()),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => widget.onConfirm(_position),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Esconder bomba'),
            ),
          ],
        ),
      ),
    );
  }
}
