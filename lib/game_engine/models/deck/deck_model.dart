import 'package:equatable/equatable.dart';
import '../card/card_model.dart';

class DeckModel extends Equatable {
  const DeckModel({
    required this.drawPile,
    required this.discardPile,
  });

  final List<CardModel> drawPile;
  final List<CardModel> discardPile;

  int get drawPileCount => drawPile.length;
  CardModel? get topDiscard => discardPile.isEmpty ? null : discardPile.last;

  DeckModel copyWith({
    List<CardModel>? drawPile,
    List<CardModel>? discardPile,
  }) {
    return DeckModel(
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
    );
  }

  @override
  List<Object?> get props => [drawPile, discardPile];

  Map<String, dynamic> toJson() => {
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
      };

  factory DeckModel.fromJson(Map<String, dynamic> j) => DeckModel(
        drawPile: (j['drawPile'] as List)
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
        discardPile: (j['discardPile'] as List)
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
