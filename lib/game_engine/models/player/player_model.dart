import 'package:equatable/equatable.dart';
import '../card/card_model.dart';
import 'player_status.dart';

class PlayerModel extends Equatable {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.hand,
    this.status = PlayerStatus.active,
    this.isHost = false,
  });

  final String id;
  final String name;
  final List<CardModel> hand;
  final PlayerStatus status;
  final bool isHost;

  bool get isAlive => status == PlayerStatus.active;
  int get cardCount => hand.length;

  PlayerModel copyWith({
    List<CardModel>? hand,
    PlayerStatus? status,
    bool? isHost,
  }) {
    return PlayerModel(
      id: id,
      name: name,
      hand: hand ?? this.hand,
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [id, name, hand, status, isHost];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'status': status.name,
        'isHost': isHost,
      };

  factory PlayerModel.fromJson(Map<String, dynamic> j) => PlayerModel(
        id: j['id'] as String,
        name: j['name'] as String,
        hand: (j['hand'] as List)
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        status: PlayerStatus.values.byName(j['status'] as String),
        isHost: j['isHost'] as bool,
      );
}
