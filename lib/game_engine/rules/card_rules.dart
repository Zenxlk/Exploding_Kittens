import '../models/card/card_model.dart';
import '../models/card/card_type.dart';
import '../models/game/game_state.dart';
import '../models/player/player_model.dart';
import '../models/turn/turn_model.dart';

/// Valida qué cartas puede jugar el jugador activo en cada fase.
abstract final class CardRules {
  /// ¿Puede el jugador jugar esta carta ahora?
  static bool canPlay(CardModel card, GameState state) {
    final player = state.currentPlayer;
    if (player == null) return false;
    if (player.id != state.turn.currentPlayerId) return false;
    if (state.turn.phase != TurnPhase.playing) return false;
    if (!card.type.isPlayable) return false;
    if (!player.hand.any((c) => c.id == card.id)) return false;
    return true;
  }

  /// ¿Puede el jugador jugar Nope ahora?
  static bool canNope(PlayerModel player, GameState state) {
    if (state.turn.phase != TurnPhase.nopeWindow) return false;
    if (state.pendingAction == null) return false;
    return player.hand.any((c) => c.type == CardType.nope);
  }

  /// ¿Puede el jugador usar Defuse en este momento?
  static bool canDefuse(PlayerModel player) =>
      player.hand.any((c) => c.type == CardType.defuse);

  /// Valida par de gatos: exactamente 2 cartas del mismo tipo gato.
  static bool isValidCatPair(List<CardModel> cards) {
    if (cards.length != 2) return false;
    if (!cards.first.type.isCatCard) return false;
    return cards.every((c) => c.type == cards.first.type);
  }

  /// Valida trío de gatos: exactamente 3 cartas del mismo tipo gato.
  static bool isValidCatTrio(List<CardModel> cards) {
    if (cards.length != 3) return false;
    if (!cards.first.type.isCatCard) return false;
    return cards.every((c) => c.type == cards.first.type);
  }
}
