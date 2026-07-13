import 'package:exploding_kittens/game_engine/engine/action_processor.dart';
import 'package:exploding_kittens/game_engine/models/card/card_model.dart';
import 'package:exploding_kittens/game_engine/models/card/card_type.dart';
import 'package:exploding_kittens/game_engine/models/deck/deck_model.dart';
import 'package:exploding_kittens/game_engine/models/game/game_config.dart';
import 'package:exploding_kittens/game_engine/models/game/game_state.dart';
import 'package:exploding_kittens/game_engine/models/player/player_model.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_action.dart';
import 'package:exploding_kittens/game_engine/models/turn/turn_model.dart';
import 'package:flutter_test/flutter_test.dart';

GameState baseState({
  required List<PlayerModel> players,
  required DeckModel deck,
  String? currentPlayerId,
}) {
  return GameState(
    id: 'game-1',
    config: const GameConfig(playerCount: 2),
    players: players,
    deck: deck,
    turn: TurnModel(
      currentPlayerId: currentPlayerId ?? players.first.id,
      phase: TurnPhase.playing,
    ),
    phase: GamePhase.playing,
  );
}

void main() {
  group('Defuse — bomba reinsertada sin duplicarse', () {
    test('reinserta exactamente la bomba robada, no otra', () {
      const bomb = CardModel(id: 'bomb-1', type: CardType.explodingKitten);
      const skip = CardModel(id: 'c-skip', type: CardType.skip);
      const attack = CardModel(id: 'c-attack', type: CardType.attack);
      const defuse = CardModel(id: 'defuse-1', type: CardType.defuse);

      final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [defuse]);
      final p2 = PlayerModel(id: 'p2', name: 'B', hand: const []);

      final state = baseState(
        players: [p1, p2],
        deck: const DeckModel(
          drawPile: [bomb, skip, attack],
          discardPile: [],
        ),
        currentPlayerId: 'p1',
      );

      final afterDraw = ActionProcessor.process(
        const DrawCardAction(playerId: 'p1'),
        state,
      );

      expect(afterDraw.turn.phase, TurnPhase.resolving);
      expect(afterDraw.pendingBomb, bomb);
      expect(afterDraw.deck.drawPile, [skip, attack]);

      final afterDefuse = ActionProcessor.process(
        const DefuseBombAction(
          playerId: 'p1',
          defuseCard: defuse,
          insertAtPosition: 1,
        ),
        afterDraw,
      );

      // La bomba se reinserta exactamente donde se pidió, sin duplicarse ni
      // desaparecer, y el resto del mazo queda intacto.
      expect(afterDefuse.deck.drawPile, [skip, bomb, attack]);
      expect(afterDefuse.pendingBomb, isNull);
      expect(
        afterDefuse.deck.drawPile.where((c) => c.id == bomb.id).length,
        1,
      );
      expect(
        afterDefuse.playerById('p1')!.hand.any((c) => c.id == defuse.id),
        isFalse,
      );
    });
  });

  group('Nope window — efectos diferidos', () {
    test('Favor no roba la carta hasta resolver la ventana sin Nope', () {
      const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
      const targetCard = CardModel(id: 'target-1', type: CardType.skip);

      final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [favorCard]);
      final p2 = PlayerModel(id: 'p2', name: 'B', hand: const [targetCard]);

      final state = baseState(
        players: [p1, p2],
        deck: const DeckModel(drawPile: [], discardPile: []),
        currentPlayerId: 'p1',
      );

      const action = PlayFavorAction(
        playerId: 'p1',
        card: favorCard,
        targetPlayerId: 'p2',
      );

      final afterPlay = ActionProcessor.process(action, state);

      // Ventana abierta, pero el robo aún NO ocurrió.
      expect(afterPlay.turn.phase, TurnPhase.nopeWindow);
      expect(afterPlay.pendingAction, action);
      expect(afterPlay.playerById('p2')!.hand, [targetCard]);
      expect(afterPlay.playerById('p1')!.hand, isEmpty);

      final resolved = ActionProcessor.resolveNopeWindow(afterPlay);

      // Ya no se resuelve solo: espera a que p2 elija qué carta entregar
      // (ver ChooseCardAction) — el robo todavía no ocurrió.
      expect(resolved.turn.phase, TurnPhase.awaitingCardChoice);
      expect(resolved.pendingAction, action);
      expect(resolved.playerById('p1')!.hand, isEmpty);
      expect(resolved.playerById('p2')!.hand, [targetCard]);

      final chosen = ActionProcessor.process(
        const ChooseCardAction(playerId: 'p2', cardId: 'target-1'),
        resolved,
      );

      expect(chosen.turn.phase, TurnPhase.playing);
      expect(chosen.pendingAction, isNull);
      expect(chosen.playerById('p1')!.hand, [targetCard]);
      expect(chosen.playerById('p2')!.hand, isEmpty);
    });

    test('un Nope impar cancela el robo de Favor', () {
      const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
      const targetCard = CardModel(id: 'target-1', type: CardType.skip);
      const nopeCard = CardModel(id: 'nope-1', type: CardType.nope);

      final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [favorCard]);
      final p2 = PlayerModel(
        id: 'p2',
        name: 'B',
        hand: const [targetCard, nopeCard],
      );

      final state = baseState(
        players: [p1, p2],
        deck: const DeckModel(drawPile: [], discardPile: []),
        currentPlayerId: 'p1',
      );

      final afterPlay = ActionProcessor.process(
        const PlayFavorAction(
          playerId: 'p1',
          card: favorCard,
          targetPlayerId: 'p2',
        ),
        state,
      );

      final afterNope = ActionProcessor.process(
        const NopeAction(playerId: 'p2', nopeCard: nopeCard),
        afterPlay,
      );
      expect(afterNope.turn.isNoped, isTrue);

      final resolved = ActionProcessor.resolveNopeWindow(afterNope);

      // Cancelado: nadie roba nada, el turno sigue en juego.
      expect(resolved.turn.phase, TurnPhase.playing);
      expect(resolved.turn.nopeChainCount, 0);
      expect(resolved.playerById('p2')!.hand, [targetCard]);
      expect(resolved.playerById('p1')!.hand, isEmpty);
    });

    test(
      'tras resolver un Favor, el turno sigue en el mismo jugador y su '
      'siguiente robo sí pasa el turno al objetivo',
      () {
        const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
        const targetCard = CardModel(id: 'target-1', type: CardType.skip);
        const nextCard = CardModel(id: 'next-1', type: CardType.tacocat);

        final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [favorCard]);
        final p2 = PlayerModel(id: 'p2', name: 'B', hand: const [targetCard]);

        final state = baseState(
          players: [p1, p2],
          deck: const DeckModel(drawPile: [nextCard], discardPile: []),
          currentPlayerId: 'p1',
        );

        final afterPlay = ActionProcessor.process(
          const PlayFavorAction(
            playerId: 'p1',
            card: favorCard,
            targetPlayerId: 'p2',
          ),
          state,
        );
        final resolved = ActionProcessor.resolveNopeWindow(afterPlay);

        // El turno sigue siendo de p1 — jugar Favor no lo termina —, pero
        // ahora espera a que p2 elija qué carta entregar.
        expect(resolved.turn.currentPlayerId, 'p1');
        expect(resolved.turn.phase, TurnPhase.awaitingCardChoice);

        final chosen = ActionProcessor.process(
          const ChooseCardAction(playerId: 'p2', cardId: 'target-1'),
          resolved,
        );
        expect(chosen.turn.phase, TurnPhase.playing);

        final afterDraw = ActionProcessor.process(
          const DrawCardAction(playerId: 'p1'),
          chosen,
        );

        // El robo normal de p1 sí debe pasar el turno a p2.
        expect(afterDraw.turn.currentPlayerId, 'p2');
        expect(afterDraw.turn.phase, TurnPhase.playing);
        expect(afterDraw.turnCount, chosen.turnCount + 1);
      },
    );

    test(
      'tras resolver un par de gatos, el robo del jugador activo sí pasa '
      'el turno',
      () {
        const cat1 = CardModel(id: 'cat-1', type: CardType.tacocat);
        const cat2 = CardModel(id: 'cat-2', type: CardType.tacocat);
        const targetCard = CardModel(id: 'target-1', type: CardType.skip);
        const nextCard = CardModel(id: 'next-1', type: CardType.attack);

        final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [cat1, cat2]);
        final p2 = PlayerModel(id: 'p2', name: 'B', hand: const [targetCard]);

        final state = baseState(
          players: [p1, p2],
          deck: const DeckModel(drawPile: [nextCard], discardPile: []),
          currentPlayerId: 'p1',
        );

        final afterPlay = ActionProcessor.process(
          const PlayCatPairAction(
            playerId: 'p1',
            cards: [cat1, cat2],
            targetPlayerId: 'p2',
          ),
          state,
        );
        final resolved = ActionProcessor.resolveNopeWindow(afterPlay);

        expect(resolved.turn.currentPlayerId, 'p1');
        expect(resolved.turn.phase, TurnPhase.playing);
        expect(resolved.playerById('p1')!.hand, [targetCard]);

        final afterDraw = ActionProcessor.process(
          const DrawCardAction(playerId: 'p1'),
          resolved,
        );

        expect(afterDraw.turn.currentPlayerId, 'p2');
      },
    );

    test(
      'un Nope que cancela un Favor deja el turno intacto para que el '
      'jugador activo lo siga jugando con normalidad',
      () {
        const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
        const targetCard = CardModel(id: 'target-1', type: CardType.skip);
        const nopeCard = CardModel(id: 'nope-1', type: CardType.nope);
        const nextCard = CardModel(id: 'next-1', type: CardType.attack);

        final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [favorCard]);
        final p2 = PlayerModel(
          id: 'p2',
          name: 'B',
          hand: const [targetCard, nopeCard],
        );

        final state = baseState(
          players: [p1, p2],
          deck: const DeckModel(drawPile: [nextCard], discardPile: []),
          currentPlayerId: 'p1',
        );

        final afterPlay = ActionProcessor.process(
          const PlayFavorAction(
            playerId: 'p1',
            card: favorCard,
            targetPlayerId: 'p2',
          ),
          state,
        );
        final afterNope = ActionProcessor.process(
          const NopeAction(playerId: 'p2', nopeCard: nopeCard),
          afterPlay,
        );
        final resolved = ActionProcessor.resolveNopeWindow(afterNope);

        expect(resolved.turn.currentPlayerId, 'p1');
        expect(resolved.turn.phase, TurnPhase.playing);

        final afterDraw = ActionProcessor.process(
          const DrawCardAction(playerId: 'p1'),
          resolved,
        );

        expect(afterDraw.turn.currentPlayerId, 'p2');
      },
    );

    test('Shuffle no baraja el mazo hasta resolver la ventana', () {
      const shuffleCard = CardModel(id: 'shuffle-1', type: CardType.shuffle);
      final drawPile = List.generate(
        10,
        (i) => CardModel(id: 'c$i', type: CardType.skip),
      );

      final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [shuffleCard]);
      final p2 = PlayerModel(id: 'p2', name: 'B', hand: const []);

      final state = baseState(
        players: [p1, p2],
        deck: DeckModel(drawPile: drawPile, discardPile: const []),
        currentPlayerId: 'p1',
      );

      final afterPlay = ActionProcessor.process(
        PlayCardAction(playerId: 'p1', card: shuffleCard),
        state,
      );

      // El orden del mazo no cambió todavía.
      expect(afterPlay.turn.phase, TurnPhase.nopeWindow);
      expect(afterPlay.deck.drawPile, drawPile);

      final resolved = ActionProcessor.resolveNopeWindow(afterPlay);

      // Mismo conjunto de cartas, mazo ya barajado (o al menos resuelto).
      expect(resolved.turn.phase, TurnPhase.playing);
      expect(
        resolved.deck.drawPile.map((c) => c.id).toSet(),
        drawPile.map((c) => c.id).toSet(),
      );
    });

    test(
      'Favor contra un objetivo sin cartas se resuelve solo, sin pedirle '
      'que elija nada',
      () {
        const favorCard = CardModel(id: 'favor-1', type: CardType.favor);
        final p1 = PlayerModel(id: 'p1', name: 'A', hand: const [favorCard]);
        final p2 = PlayerModel(id: 'p2', name: 'B', hand: const []);

        final state = baseState(
          players: [p1, p2],
          deck: const DeckModel(drawPile: [], discardPile: []),
          currentPlayerId: 'p1',
        );

        final afterPlay = ActionProcessor.process(
          const PlayFavorAction(
            playerId: 'p1',
            card: favorCard,
            targetPlayerId: 'p2',
          ),
          state,
        );
        final resolved = ActionProcessor.resolveNopeWindow(afterPlay);

        // No hay nada que elegir — no se queda esperando una elección.
        expect(resolved.turn.phase, TurnPhase.playing);
        expect(resolved.pendingAction, isNull);
        expect(resolved.playerById('p1')!.hand, isEmpty);
        expect(resolved.playerById('p2')!.hand, isEmpty);
      },
    );
  });

  group('Eliminación — orden cronológico', () {
    test(
        'GameState.eliminationOrder y GameResult.eliminationOrder reflejan '
        'el orden real en que explotaron, no el orden de la lista de '
        'jugadores', () {
      const bomb1 = CardModel(id: 'bomb-1', type: CardType.explodingKitten);
      const bomb2 = CardModel(id: 'bomb-2', type: CardType.explodingKitten);

      final p1 = PlayerModel(id: 'p1', name: 'A', hand: const []);
      final p2 = PlayerModel(id: 'p2', name: 'B', hand: const []);
      final p3 = PlayerModel(id: 'p3', name: 'C', hand: const []);

      // p3 (último en la lista de jugadores) explota primero.
      var state = baseState(
        players: [p1, p2, p3],
        deck: const DeckModel(drawPile: [bomb1], discardPile: []),
        currentPlayerId: 'p3',
      );
      state = ActionProcessor.process(
        const DrawCardAction(playerId: 'p3'),
        state,
      );

      expect(state.eliminationOrder, ['p3']);

      // p1 (primero en la lista) explota después.
      state = state.copyWith(
        deck: const DeckModel(drawPile: [bomb2], discardPile: []),
        turn: state.turn.copyWith(
          currentPlayerId: 'p1',
          phase: TurnPhase.playing,
        ),
      );
      state = ActionProcessor.process(
        const DrawCardAction(playerId: 'p1'),
        state,
      );

      expect(state.eliminationOrder, ['p3', 'p1']);
      expect(state.result?.eliminationOrder, ['p3', 'p1']);
      expect(state.result?.winnerId, 'p2');
    });
  });
}
