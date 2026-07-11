import '../../core/errors/exceptions.dart';
import '../models/card/card_model.dart';
import '../models/game/game_state.dart';
import '../models/turn/turn_action.dart';
import '../models/turn/turn_model.dart';
import 'card_rules.dart';

/// Orquestador de reglas. Punto único de validación antes de aplicar acciones.
abstract final class GameRules {
  static void validate(TurnAction action, GameState state) {
    switch (action) {
      case DrawCardAction():
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeInPhase(state, TurnPhase.playing);
      case PlayCardAction(:final card):
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeAbleToPlay(card, state);
      case PlayFavorAction(:final card, :final targetPlayerId):
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeAbleToPlay(card, state);
        _targetMustBeAlive(targetPlayerId, state);
        _targetMustNotBeSelf(action.playerId, targetPlayerId);
      case PlayCatPairAction(:final cards, :final targetPlayerId):
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeInPhase(state, TurnPhase.playing);
        if (!CardRules.isValidCatPair(cards)) {
          throw const InvalidActionException('Par de gatos inválido');
        }
        _playerMustHaveCards(action.playerId, cards, state);
        _targetMustBeAlive(targetPlayerId, state);
        _targetMustNotBeSelf(action.playerId, targetPlayerId);
      case PlayCatTrioAction(:final cards, :final targetPlayerId):
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeInPhase(state, TurnPhase.playing);
        if (!CardRules.isValidCatTrio(cards)) {
          throw const InvalidActionException('Trío de gatos inválido');
        }
        _playerMustHaveCards(action.playerId, cards, state);
        _targetMustBeAlive(targetPlayerId, state);
        _targetMustNotBeSelf(action.playerId, targetPlayerId);
      case DefuseBombAction():
        _mustBeCurrentPlayer(action.playerId, state);
        _mustBeInPhase(state, TurnPhase.resolving);
        if (state.pendingBomb == null) {
          throw const InvalidActionException(
            'No hay ninguna bomba pendiente de esconder',
          );
        }
        if (!CardRules.canDefuse(state.currentPlayer!)) {
          throw const InvalidActionException('No tienes Defuse');
        }
      case NopeAction(:final playerId):
        final player = state.playerById(playerId);
        if (player == null) throw const GameException('Jugador no encontrado');
        if (!CardRules.canNope(player, state)) {
          throw const InvalidActionException('No puedes jugar Nope ahora');
        }
    }
  }

  static void _mustBeCurrentPlayer(String playerId, GameState state) {
    if (state.turn.currentPlayerId != playerId) {
      throw const InvalidActionException('No es tu turno');
    }
  }

  /// `PlayCardAction`/`PlayFavorAction` ya quedan cubiertas por el chequeo de
  /// fase dentro de `CardRules.canPlay`; `DrawCardAction`, los pares/tríos de
  /// gato y `DefuseBombAction` necesitaban el mismo candado explícito. Sin
  /// esto, una acción "atrasada" por latencia de red (p. ej. un robo que
  /// salió justo antes de que se abriera una ventana de Nope, y llega al
  /// host cuando esta ya está abierta) pasaba la validación igual,
  /// `TurnManager.advance` limpiaba `pendingAction` de golpe y cancelaba el
  /// `Timer` de `resolveNopeWindow` en `GameNotifier` (se reprograma en cada
  /// cambio de estado) — el Favor/par de gatos pendiente se perdía sin
  /// resolverse y el turno quedaba en un estado inconsistente.
  static void _mustBeInPhase(GameState state, TurnPhase phase) {
    if (state.turn.phase != phase) {
      throw const InvalidActionException('No puedes hacer eso ahora');
    }
  }

  static void _mustBeAbleToPlay(CardModel card, GameState state) {
    if (!CardRules.canPlay(card, state)) {
      throw InvalidActionException('No puedes jugar ${card.type.name}');
    }
  }

  static void _targetMustBeAlive(String targetId, GameState state) {
    final target = state.playerById(targetId);
    if (target == null || !target.isAlive) {
      throw const InvalidActionException('El objetivo no está en juego');
    }
  }

  static void _targetMustNotBeSelf(String playerId, String targetId) {
    if (playerId == targetId) {
      throw const InvalidActionException('No puedes elegirte a ti mismo');
    }
  }

  static void _playerMustHaveCards(
      String playerId, List<CardModel> cards, GameState state) {
    final player = state.playerById(playerId);
    if (player == null) throw const GameException('Jugador no encontrado');
    for (final card in cards) {
      if (!player.hand.any((c) => c.id == card.id)) {
        throw InvalidActionException('No tienes la carta ${card.id}');
      }
    }
  }
}
