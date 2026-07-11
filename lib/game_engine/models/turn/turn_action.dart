import 'package:equatable/equatable.dart';
import '../card/card_model.dart';

/// Todas las acciones posibles que un jugador puede ejecutar en su turno.
///
/// Se serializa con un discriminador `type` (mismo patrón que
/// `WsMessage.fromJson`) porque viaja por red en Fase 5: el cliente manda la
/// acción al host dentro de un `ActionMessage`, y `GameState.pendingAction`
/// (durante una ventana de Nope) siempre guarda una instancia concreta.
///
/// Extiende `Equatable` (igual que el resto de modelos del motor) para que
/// dos acciones reconstruidas por separado —p. ej. una local y otra que
/// llegó por red y se deserializó— comparen por valor. Sin esto,
/// `GameState`'s `pendingAction` (declarado `Object?`) rompería la igualdad
/// estructural de `GameState` en cuanto no fueran instancias `const`
/// canonicalizadas idénticas.
sealed class TurnAction extends Equatable {
  const TurnAction({required this.playerId});
  final String playerId;

  Map<String, dynamic> toJson();

  static TurnAction fromJson(Map<String, dynamic> j) {
    return switch (j['type'] as String) {
      'draw_card' => DrawCardAction._fromJson(j),
      'play_card' => PlayCardAction._fromJson(j),
      'play_favor' => PlayFavorAction._fromJson(j),
      'play_cat_pair' => PlayCatPairAction._fromJson(j),
      'play_cat_trio' => PlayCatTrioAction._fromJson(j),
      'defuse_bomb' => DefuseBombAction._fromJson(j),
      'nope' => NopeAction._fromJson(j),
      final t => throw FormatException('Unknown TurnAction type: $t'),
    };
  }
}

/// Robar la carta de arriba del mazo
final class DrawCardAction extends TurnAction {
  const DrawCardAction({required super.playerId});

  factory DrawCardAction._fromJson(Map<String, dynamic> j) =>
      DrawCardAction(playerId: j['playerId'] as String);

  @override
  Map<String, dynamic> toJson() => {'type': 'draw_card', 'playerId': playerId};

  @override
  List<Object?> get props => [playerId];
}

/// Jugar una carta de la mano (sin objetivo)
final class PlayCardAction extends TurnAction {
  const PlayCardAction({
    required super.playerId,
    required this.card,
  });
  final CardModel card;

  factory PlayCardAction._fromJson(Map<String, dynamic> j) => PlayCardAction(
        playerId: j['playerId'] as String,
        card: CardModel.fromJson(j['card'] as Map<String, dynamic>),
      );

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'play_card', 'playerId': playerId, 'card': card.toJson()};

  @override
  List<Object?> get props => [playerId, card];
}

/// Favor: pedir una carta a otro jugador
final class PlayFavorAction extends TurnAction {
  const PlayFavorAction({
    required super.playerId,
    required this.card,
    required this.targetPlayerId,
  });
  final CardModel card;
  final String targetPlayerId;

  factory PlayFavorAction._fromJson(Map<String, dynamic> j) => PlayFavorAction(
        playerId: j['playerId'] as String,
        card: CardModel.fromJson(j['card'] as Map<String, dynamic>),
        targetPlayerId: j['targetPlayerId'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'play_favor',
        'playerId': playerId,
        'card': card.toJson(),
        'targetPlayerId': targetPlayerId,
      };

  @override
  List<Object?> get props => [playerId, card, targetPlayerId];
}

/// Jugar par de gatos para robar carta aleatoria a otro
final class PlayCatPairAction extends TurnAction {
  const PlayCatPairAction({
    required super.playerId,
    required this.cards, // exactamente 2 cartas del mismo tipo gato
    required this.targetPlayerId,
  });
  final List<CardModel> cards;
  final String targetPlayerId;

  factory PlayCatPairAction._fromJson(Map<String, dynamic> j) =>
      PlayCatPairAction(
        playerId: j['playerId'] as String,
        cards: (j['cards'] as List)
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        targetPlayerId: j['targetPlayerId'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'play_cat_pair',
        'playerId': playerId,
        'cards': cards.map((c) => c.toJson()).toList(),
        'targetPlayerId': targetPlayerId,
      };

  @override
  List<Object?> get props => [playerId, cards, targetPlayerId];
}

/// Jugar trío de gatos para ver la mano de otro y elegir
final class PlayCatTrioAction extends TurnAction {
  const PlayCatTrioAction({
    required super.playerId,
    required this.cards, // exactamente 3 cartas del mismo tipo gato
    required this.targetPlayerId,
    required this.chosenCardId,
  });
  final List<CardModel> cards;
  final String targetPlayerId;
  final String chosenCardId;

  factory PlayCatTrioAction._fromJson(Map<String, dynamic> j) =>
      PlayCatTrioAction(
        playerId: j['playerId'] as String,
        cards: (j['cards'] as List)
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        targetPlayerId: j['targetPlayerId'] as String,
        chosenCardId: j['chosenCardId'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'play_cat_trio',
        'playerId': playerId,
        'cards': cards.map((c) => c.toJson()).toList(),
        'targetPlayerId': targetPlayerId,
        'chosenCardId': chosenCardId,
      };

  @override
  List<Object?> get props => [playerId, cards, targetPlayerId, chosenCardId];
}

/// Usar Defuse cuando se roba un Exploding Kitten
final class DefuseBombAction extends TurnAction {
  const DefuseBombAction({
    required super.playerId,
    required this.defuseCard,
    required this.insertAtPosition, // dónde reinserta la bomba
  });
  final CardModel defuseCard;
  final int insertAtPosition;

  factory DefuseBombAction._fromJson(Map<String, dynamic> j) =>
      DefuseBombAction(
        playerId: j['playerId'] as String,
        defuseCard: CardModel.fromJson(j['defuseCard'] as Map<String, dynamic>),
        insertAtPosition: j['insertAtPosition'] as int,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'defuse_bomb',
        'playerId': playerId,
        'defuseCard': defuseCard.toJson(),
        'insertAtPosition': insertAtPosition,
      };

  @override
  List<Object?> get props => [playerId, defuseCard, insertAtPosition];
}

/// Jugar Nope sobre la acción anterior en cadena
final class NopeAction extends TurnAction {
  const NopeAction({
    required super.playerId,
    required this.nopeCard,
  });
  final CardModel nopeCard;

  factory NopeAction._fromJson(Map<String, dynamic> j) => NopeAction(
        playerId: j['playerId'] as String,
        nopeCard: CardModel.fromJson(j['nopeCard'] as Map<String, dynamic>),
      );

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'nope', 'playerId': playerId, 'nopeCard': nopeCard.toJson()};

  @override
  List<Object?> get props => [playerId, nopeCard];
}
