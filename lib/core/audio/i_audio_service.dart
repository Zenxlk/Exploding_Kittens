/// Reproductor de audio de la app: efectos de un solo disparo y música de
/// fondo en loop. Interfaz separada de la implementación real (que usa
/// `audioplayers`, con canales de plataforma) para poder sustituirla por un
/// fake en tests de widgets sin depender de plugins nativos.
abstract interface class IAudioService {
  /// Reproduce un efecto de sonido una vez. Nunca lanza: un fallo de audio
  /// (asset faltante, sin salida de sonido, plataforma no soportada) no
  /// debe interrumpir la partida.
  Future<void> playEffect(String assetPath, {required double volume});

  /// Reproduce música de fondo en loop. Si [enabled] es falso, detiene la
  /// música actual en su lugar. Si ya está sonando el mismo [assetPath],
  /// solo ajusta el volumen sin reiniciar la pista.
  Future<void> playMusic(
    String assetPath, {
    required bool enabled,
    required double volume,
  });

  Future<void> stopMusic();

  Future<void> dispose();
}
