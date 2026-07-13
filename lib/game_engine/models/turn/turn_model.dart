import 'package:equatable/equatable.dart';

enum TurnPhase {
  playing, // el jugador activo puede jugar cartas
  nopeWindow, // ventana abierta para que otros jueguen Nope
  drawRequired, // el jugador debe robar para terminar turno
  resolving, // se está aplicando el efecto de una carta
  ended, // turno terminado, pasa al siguiente
  // Alguien (no necesariamente el jugador activo) debe elegir una carta
  // concreta para resolver una acción pendiente — ver GameState.pendingAction
  // y ChooseCardAction. Hoy solo la usa Favor (el objetivo elige qué carta
  // de su propia mano entregar); pensada para reusarse con cualquier otra
  // "elegí una carta concreta" futura (p. ej. el trío de gatos, donde en
  // cambio elegiría el actor desde la mano del rival).
  awaitingCardChoice,
}

class TurnModel extends Equatable {
  const TurnModel({
    required this.currentPlayerId,
    required this.phase,
    this.actionsLeft = 1, // Attack puede dejarlo en 2
    this.nopeChainCount = 0,
  });

  final String currentPlayerId;
  final TurnPhase phase;
  final int actionsLeft; // veces que el jugador debe robar (Attack chains)
  final int nopeChainCount; // número de Nopes en cadena (par = cancelado)

  bool get isNoped => nopeChainCount.isOdd;

  TurnModel copyWith({
    String? currentPlayerId,
    TurnPhase? phase,
    int? actionsLeft,
    int? nopeChainCount,
  }) {
    return TurnModel(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      phase: phase ?? this.phase,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      nopeChainCount: nopeChainCount ?? this.nopeChainCount,
    );
  }

  @override
  List<Object?> get props =>
      [currentPlayerId, phase, actionsLeft, nopeChainCount];

  Map<String, dynamic> toJson() => {
        'currentPlayerId': currentPlayerId,
        'phase': phase.name,
        'actionsLeft': actionsLeft,
        'nopeChainCount': nopeChainCount,
      };

  factory TurnModel.fromJson(Map<String, dynamic> j) => TurnModel(
        currentPlayerId: j['currentPlayerId'] as String,
        phase: TurnPhase.values.byName(j['phase'] as String),
        actionsLeft: j['actionsLeft'] as int,
        nopeChainCount: j['nopeChainCount'] as int,
      );
}
