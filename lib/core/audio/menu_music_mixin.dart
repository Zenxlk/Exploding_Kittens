import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:exploding_kittens/core/constants/asset_paths.dart';
import 'package:exploding_kittens/features/settings/domain/app_settings.dart';
import 'package:exploding_kittens/features/settings/presentation/providers/settings_providers.dart';
import 'audio_service.dart';
import 'i_audio_service.dart';

/// Reproduce `AssetPaths.musicMenu` en loop mientras el widget está montado.
/// Pensado para las pantallas fuera de partida (Splash/Home/Lobby/Ajustes):
/// a diferencia de `GameScreen`/`GameOverScreen`, deliberadamente NO frena
/// la música en `dispose()` — todas piden el mismo asset, y `AudioService`
/// ya no reinicia la pista si ya está sonando, así que navegar entre ellas
/// no corta ni reinicia la música. Quien sí la corta es la siguiente
/// pantalla que pida una pista distinta (p. ej. `GameScreen` al entrar a
/// partida).
mixin MenuMusicMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final IAudioService _menuAudioService;

  @override
  void initState() {
    super.initState();
    _menuAudioService = ref.read(audioServiceProvider);
    syncMenuMusic();
  }

  void syncMenuMusic() {
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    _menuAudioService.playMusic(
      AssetPaths.musicMenu,
      enabled: settings.musicEnabled,
      volume: settings.volume,
    );
  }
}
