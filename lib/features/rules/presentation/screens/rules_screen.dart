import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:exploding_kittens/core/theme/app_colors.dart';
import 'package:exploding_kittens/core/theme/app_text_styles.dart';
import 'package:exploding_kittens/features/game/presentation/providers/card_asset_provider.dart';
import 'package:exploding_kittens/features/game/presentation/widgets/card_widget.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';

/// Explicación en criollo de las reglas ya implementadas, con las cartas de
/// verdad para que se entienda de un vistazo. No es el manual oficial del
/// juego (ver DISCLAIMER.md) — son descripciones propias de cómo se juega
/// *en esta versión*, así que si algo todavía no está soportado (como el
/// trío de gatos) se aclara en vez de prometerlo.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(cardAssetResolverProvider).value;
    final assetPathFor = resolver?.faceAssetFor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        title: Text('Cómo jugar', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _IntroSection(),
          const Gap(28),
          _SectionHeader('Cartas especiales'),
          const Gap(8),
          _RuleCardRow(
            type: CardType.explodingKitten,
            assetPathFor: assetPathFor,
            description: 'Si la robás y no tenés un Defuse, quedás '
                'eliminado. No se juega desde la mano: solo aparece cuando '
                'te toca en el mazo.',
          ),
          _RuleCardRow(
            type: CardType.defuse,
            assetPathFor: assetPathFor,
            description: 'Te salva de una Exploding Kitten: la escondés de '
                'nuevo en el mazo, en la posición que elijas.',
          ),
          _RuleCardRow(
            type: CardType.nope,
            assetPathFor: assetPathFor,
            description: 'Cancela la última carta jugada (menos una '
                'Exploding Kitten o un Defuse). La puede jugar cualquiera, '
                'en cualquier momento, aunque no sea su turno — incluso '
                'para cancelar otro Nope.',
          ),
          const Gap(20),
          _SectionHeader('Cartas de acción'),
          const Gap(8),
          _RuleCardRow(
            type: CardType.attack,
            assetPathFor: assetPathFor,
            description: 'Termina tu turno sin robar, y el siguiente '
                'jugador tiene que jugar dos turnos seguidos.',
          ),
          _RuleCardRow(
            type: CardType.skip,
            assetPathFor: assetPathFor,
            description: 'Termina tu turno sin robar. Ojo: si te atacaron '
                'y te tocan dos turnos, un Skip solo te libra de uno — '
                'necesitás jugar o robar una vez más.',
          ),
          _RuleCardRow(
            type: CardType.favor,
            assetPathFor: assetPathFor,
            description: 'Elegís a otro jugador y te tiene que dar una '
                'carta de su mano — la elige él, no vos.',
          ),
          _RuleCardRow(
            type: CardType.shuffle,
            assetPathFor: assetPathFor,
            description: 'Reparte de nuevo el mazo al azar. Nadie ve las '
                'cartas.',
          ),
          _RuleCardRow(
            type: CardType.seeTheFuture,
            assetPathFor: assetPathFor,
            description: 'Mirás las 3 cartas de arriba del mazo, en orden, '
                'sin cambiar nada.',
          ),
          const Gap(20),
          _SectionHeader('Gatos'),
          const Gap(8),
          const _CatCardsExplainer(),
          const Gap(8),
          _RuleCardRow(
            type: CardType.tacocat,
            assetPathFor: assetPathFor,
            description: 'No hace nada sola — necesita pareja.',
          ),
          _RuleCardRow(
            type: CardType.rainbowRalphingCat,
            assetPathFor: assetPathFor,
            description: 'No hace nada sola — necesita pareja.',
          ),
          _RuleCardRow(
            type: CardType.beardedDragon,
            assetPathFor: assetPathFor,
            description: 'No hace nada sola — necesita pareja.',
          ),
          _RuleCardRow(
            type: CardType.cattermelon,
            assetPathFor: assetPathFor,
            description: 'No hace nada sola — necesita pareja.',
          ),
          _RuleCardRow(
            type: CardType.hairyPotatoCat,
            assetPathFor: assetPathFor,
            description: 'No hace nada sola — necesita pareja.',
          ),
        ],
      ),
    );
  }
}

class _IntroSection extends StatelessWidget {
  const _IntroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('El objetivo'),
        const Gap(6),
        Text(
          'Sé el último gato en pie. El resto va explotando (a menos que '
          'se defusen a tiempo) hasta que solo queda uno.',
          style: AppTextStyles.body,
        ),
        const Gap(18),
        _SectionHeader('Antes de empezar'),
        const Gap(6),
        Text(
          'Cada jugador arranca con 7 cartas y 1 Defuse. El resto del mazo '
          '(con suficientes Exploding Kittens para que quede una menos que '
          'la cantidad de jugadores) se baraja y se reparte boca abajo en '
          'el centro.',
          style: AppTextStyles.body,
        ),
        const Gap(18),
        _SectionHeader('Tu turno'),
        const Gap(6),
        Text(
          'Podés jugar tantas cartas de acción como quieras, o ninguna. '
          'Cuando termines, siempre tenés que robar una carta del mazo '
          'para pasar el turno. Si te sale una Exploding Kitten y no '
          'tenés Defuse, quedás eliminado ahí mismo.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}

class _CatCardsExplainer extends StatelessWidget {
  const _CatCardsExplainer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ninguna carta de gato hace algo sola: son "cartas basura" '
            'que solo sirven combinadas.',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(4),
          Text(
            'Juntá 2 iguales para elegir a otro jugador y robarle una '
            'carta al azar de su mano. El trío (3 iguales, para elegir vos '
            'mismo qué carta robarle) todavía no está disponible en esta '
            'versión.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.75),
            ),
          ),
          const Gap(4),
          Text(
            'Si te quedan solo gatos sueltos sin pareja, no hay drama: '
            'no podés jugarlos, así que simplemente tocá el mazo para '
            'robar y seguir.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.primary,
        letterSpacing: 1.4,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _RuleCardRow extends StatelessWidget {
  const _RuleCardRow({
    required this.type,
    required this.description,
    this.assetPathFor,
  });

  final CardType type;
  final String description;
  final String? Function(CardType type)? assetPathFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardWidget(
            type: type,
            assetPath: assetPathFor?.call(type),
            width: 56,
          ),
          const Gap(14),
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onBackground.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
