import 'package:equatable/equatable.dart';

class GameConfig extends Equatable {
  const GameConfig({
    required this.playerCount,
    this.includeExpansion = false,
    this.botCount = 0,
    this.seed,
  });

  final int playerCount;
  final bool includeExpansion;
  final int botCount;
  final int? seed; // null = aleatorio; valor fijo = partida reproducible

  @override
  List<Object?> get props => [playerCount, includeExpansion, botCount, seed];

  Map<String, dynamic> toJson() => {
        'playerCount': playerCount,
        'includeExpansion': includeExpansion,
        'botCount': botCount,
        'seed': seed,
      };

  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
        playerCount: j['playerCount'] as int,
        includeExpansion: j['includeExpansion'] as bool,
        botCount: j['botCount'] as int,
        seed: j['seed'] as int?,
      );
}
