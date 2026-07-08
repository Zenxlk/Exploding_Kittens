import 'package:exploding_kittens/features/game/presentation/widgets/discard_pile_widget.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DiscardPileWidget', () {
    testWidgets('sin carta descartada muestra un hueco vacío', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const DiscardPileWidget(topCard: null)));

      expect(find.byType(DottedCardSlot), findsOneWidget);
    });

    testWidgets('con carta descartada la muestra boca arriba', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DiscardPileWidget(
            topCard: CardModel(id: 'a', type: CardType.shuffle),
          ),
        ),
      );

      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.byType(DottedCardSlot), findsNothing);
    });
  });
}
