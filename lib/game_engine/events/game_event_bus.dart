import 'dart:async';
import 'game_event.dart';

/// Bus de eventos singleton. El engine publica; la UI y la red se suscriben.
class GameEventBus {
  GameEventBus._();
  static final GameEventBus instance = GameEventBus._();

  final StreamController<GameEvent> _controller =
      StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get stream => _controller.stream;

  Stream<T> on<T extends GameEvent>() => stream.where((e) => e is T).cast<T>();

  void emit(GameEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void dispose() => _controller.close();
}
