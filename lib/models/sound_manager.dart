import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // Separate players for different sound types
  final AudioPlayer _sfxPlayer = AudioPlayer();    // Actions & effects
  final AudioPlayer _bgPlayer = AudioPlayer();     // Background music
  final AudioPlayer _alertPlayer = AudioPlayer();  // Alerts

  Timer? _stopTimer;

  // Play a sound and auto-stop after [duration] seconds
Future<void> _playSfx(String fileName, {int? stopAfterSeconds}) async {
  try {
    _stopTimer?.cancel();
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/$fileName'));
    if (stopAfterSeconds != null) {
      _stopTimer = Timer(Duration(seconds: stopAfterSeconds), () async {
        await _sfxPlayer.stop();
      });
    }
  } catch (e) {}
}

  Future<void> _playAlert(String fileName, {int? stopAfterSeconds}) async {
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sounds/$fileName'));
      if (stopAfterSeconds != null) {
        Timer(Duration(seconds: stopAfterSeconds), () {
          _alertPlayer.stop();
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _playBg(String fileName, {bool loop = false}) async {
    try {
      await _bgPlayer.stop();
      if (loop) {
        await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _bgPlayer.setReleaseMode(ReleaseMode.release);
      }
      await _bgPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> stopBg() async {
    try {
      await _bgPlayer.stop();
    } catch (e) {}
  }

  // === Action sounds (auto-stop after action duration) ===
  Future<void> comer() => _playSfx('comer.mp3', stopAfterSeconds: 3);
  Future<void> jugar() => _playSfx('jugar.mp3', stopAfterSeconds: 4);
  Future<void> dormir() => _playSfx('dormir.mp3', stopAfterSeconds: 4);
  Future<void> banar() => _playSfx('banar.mp3', stopAfterSeconds: 3);
  Future<void> fuerza() => _playSfx('fuerza.mp3', stopAfterSeconds: 3);

  // === Level & celebration sounds (play fully) ===
  Future<void> celebrar() => _playSfx('celebrar.mp3');
  Future<void> subirNivel() => _playSfx('subir.mp3');

  // === Alert sound ===
  Future<void> alerta() => _playAlert('alerta.mp3', stopAfterSeconds: 2);

  // === Intro sounds ===
  Future<void> regalo() => _playSfx('regalo.mp3');
  Future<void> nave() => _playSfx('nave.mp3');
  Future<void> aparece() => _playSfx('aparece.mp3');

  // === Background music ===
  Future<void> musicaFrase() => _playBg('musica_frase.mp3');
  Future<void> stopMusica() => stopBg();

  void dispose() {
    _stopTimer?.cancel();
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
    _alertPlayer.dispose();
  }
}
