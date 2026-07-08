import 'package:exploding_kittens/features/game/presentation/widgets/card_widget.dart';
import 'package:exploding_kittens/features/game/presentation/widgets/deck_widget.dart';
import 'package:exploding_kittens/features/game/presentation/widgets/game_table_view.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _state({
  required List<PlayerModel> players,
  required String currentPlayerId,
  TurnPhase phase = TurnPhase.playing,
  List<CardModel>? seeTheFutureCards,
}) {
  return GameState(
    id: 'g1',
    config: const GameConfig(playerCount: 2),
    players: players,
    deck: const DeckModel(drawPile: [], discardPile: []),
    turn: TurnModel(currentPlayerId: currentPlayerId, phase: phase),
    phase: GamePhase.playing,
    seeTheFutureCards: seeTheFutureCards,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GameTableView', () {
    testWidgets(
        'muestra la mano del jugador local, no la de quien tiene el '
        'turno', (tester) async {
      const me = PlayerModel(
        id: 'me',
        name: 'Ana',
        hand: [CardModel(id: 'a', type: CardType.skip)],
      );
      const other = PlayerModel(
        id: 'other',
        name: 'Beto',
        hand: [CardModel(id: 'b', type: CardType.attack)],
      );

      await tester.pumpWidget(
        _wrap(
          GameTableView(
            gameState: _state(
              players: const [me, other],
              currentPlayerId: 'other',
            ),
            localPlayerId: 'me',
            onDraw: () {},
            onPlaySimpleCard: (_) {},
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Attack'), findsNothing);
      expect(find.textContaining('Turno de Beto'), findsOneWidget);
    });

    testWidgets('el mazo no responde al tap si no es mi turno', (
      tester,
    ) async {
      const me = PlayerModel(id: 'me', name: 'Ana', hand: []);
      const other = PlayerModel(id: 'other', name: 'Beto', hand: []);
      var draws = 0;

      await tester.pumpWidget(
        _wrap(
          GameTableView(
            gameState: _state(
              players: const [me, other],
              currentPlayerId: 'other',
            ),
            localPlayerId: 'me',
            onDraw: () => draws++,
            onPlaySimpleCard: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(DeckWidget));
      expect(draws, 0);
    });

    testWidgets(
      'seleccionar una carta jugable y confirmar invoca onPlaySimpleCard',
      (tester) async {
        const skip = CardModel(id: 'a', type: CardType.skip);
        const me = PlayerModel(id: 'me', name: 'Ana', hand: [skip]);
        CardModel? played;

        await tester.pumpWidget(
          _wrap(
            GameTableView(
              gameState: _state(players: const [me], currentPlayerId: 'me'),
              localPlayerId: 'me',
              onDraw: () {},
              onPlaySimpleCard: (card) => played = card,
            ),
          ),
        );

        await tester.tap(find.byType(CardWidget));
        await tester.pump();

        expect(find.text('Jugar'), findsOneWidget);
        await tester.tap(find.text('Jugar'));
        await tester.pump();

        expect(played, skip);
        expect(find.text('Jugar'), findsNothing);
      },
    );

    testWidgets(
      'una carta sin soporte todavía deja el botón Jugar deshabilitado',
      (tester) async {
        const favor = CardModel(id: 'a', type: CardType.favor);
        const me = PlayerModel(id: 'me', name: 'Ana', hand: [favor]);

        await tester.pumpWidget(
          _wrap(
            GameTableView(
              gameState: _state(players: const [me], currentPlayerId: 'me'),
              localPlayerId: 'me',
              onDraw: () {},
              onPlaySimpleCard: (_) {},
            ),
          ),
        );

        await tester.tap(find.byType(CardWidget));
        await tester.pump();

        expect(
          find.text('Esta carta se juega en el próximo paso'),
          findsOneWidget,
        );
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'muestra el overlay de See the Future cuando el estado lo trae',
      (tester) async {
        const me = PlayerModel(id: 'me', name: 'Ana', hand: []);

        await tester.pumpWidget(
          _wrap(
            GameTableView(
              gameState: _state(
                players: const [me],
                currentPlayerId: 'me',
                seeTheFutureCards: const [
                  CardModel(id: 'a', type: CardType.skip),
                  CardModel(id: 'b', type: CardType.attack),
                  CardModel(id: 'c', type: CardType.nope),
                ],
              ),
              localPlayerId: 'me',
              onDraw: () {},
              onPlaySimpleCard: (_) {},
            ),
          ),
        );

        expect(find.text('Ves las próximas 3 cartas'), findsOneWidget);
        expect(find.text('Continuar'), findsOneWidget);
      },
    );

    testWidgets(
      'descartar el overlay lo oculta hasta la próxima revelación',
      (tester) async {
        const me = PlayerModel(id: 'me', name: 'Ana', hand: []);
        const reveal = [CardModel(id: 'a', type: CardType.skip)];

        Widget build(List<CardModel>? cards) => _wrap(
              GameTableView(
                gameState: _state(
                  players: const [me],
                  currentPlayerId: 'me',
                  seeTheFutureCards: cards,
                ),
                localPlayerId: 'me',
                onDraw: () {},
                onPlaySimpleCard: (_) {},
              ),
            );

        await tester.pumpWidget(build(reveal));
        expect(find.text('Continuar'), findsOneWidget);

        await tester.tap(find.text('Continuar'));
        await tester.pump();
        expect(find.text('Continuar'), findsNothing);

        // La misma revelación (sin pasar por null) sigue descartada.
        await tester.pumpWidget(build(reveal));
        expect(find.text('Continuar'), findsNothing);

        // Una revelación nueva (null → no-null) vuelve a mostrarse.
        await tester.pumpWidget(build(null));
        await tester.pumpWidget(build(reveal));
        expect(find.text('Continuar'), findsOneWidget);
      },
    );
  });
}
