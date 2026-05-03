import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_manager.dart';

enum GroguMood {
  feliz, cansado, dormido, hambriento, comiendo,
  jugando, triste, enfermo, muyFeliz, fuerza
}

enum GroguEtapa { bebe, aprendiz, maestro }

class GroguState extends ChangeNotifier {
  double _hambre = 80.0;
  double _felicidad = 80.0;
  double _energia = 80.0;
  double _salud = 80.0;
  int _nivel = 1;
  int _xp = 0;
  int _xpParaSiguienteNivel = 100;
  bool _subioDeNivel = false;
  GroguMood _mood = GroguMood.feliz;
  bool _isAnimatingFrame2 = false;
  Timer? _animTimer;
  Timer? _decayTimer;
  final SoundManager _sound = SoundManager();

  double get hambre => _hambre;
  double get felicidad => _felicidad;
  double get energia => _energia;
  double get salud => _salud;
  int get nivel => _nivel;
  int get xp => _xp;
  int get xpParaSiguienteNivel => _xpParaSiguienteNivel;
  double get xpProgress => _xp / _xpParaSiguienteNivel;
  bool get subioDeNivel => _subioDeNivel;
  GroguMood get mood => _mood;
  bool get isAnimatingFrame2 => _isAnimatingFrame2;

  GroguEtapa get etapa {
    if (_nivel <= 10) return GroguEtapa.bebe;
    if (_nivel <= 25) return GroguEtapa.aprendiz;
    return GroguEtapa.maestro;
  }

  String get etapaNombre {
    switch (etapa) {
      case GroguEtapa.bebe: return '🥚 Bebé Grogu';
      case GroguEtapa.aprendiz: return '⭐ Grogu Aprendiz';
      case GroguEtapa.maestro: return '🔮 Grogu Maestro Jedi';
    }
  }

  bool get puedeJugar => etapa != GroguEtapa.bebe;
  bool get puedeFuerza => etapa != GroguEtapa.bebe;

  double get groguSize {
    switch (etapa) {
      case GroguEtapa.bebe: return 160.0;
      case GroguEtapa.aprendiz: return 200.0;
      case GroguEtapa.maestro: return 230.0;
    }
  }

  GroguState() {
    _loadState();
    _startDecay();
    _startAnimation();
  }

  void _startAnimation() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _isAnimatingFrame2 = !_isAnimatingFrame2;
      notifyListeners();
    });
  }

  void _startDecay() {
    _decayTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _hambre = (_hambre - 2).clamp(0, 100);
      _felicidad = (_felicidad - 1).clamp(0, 100);
      _energia = (_energia - 1.5).clamp(0, 100);
      if (_hambre < 20 || _energia < 20 || _felicidad < 20) {
        _salud = (_salud - 0.5).clamp(0, 100);
      }
      if (_hambre < 20 || _energia < 20 || _felicidad < 20 || _salud < 30) {
        _sound.alerta();
      }
      _updateMood();
      _saveState();
      notifyListeners();
    });
  }

  void _updateMood() {
    if (_salud < 30) {
      _mood = GroguMood.enfermo;
    } else if (_hambre < 20) {
      _mood = GroguMood.hambriento;
    } else if (_energia < 20) {
      _mood = GroguMood.cansado;
    } else if (_felicidad < 20) {
      _mood = GroguMood.triste;
    } else if (_energia < 10) {
      _mood = GroguMood.dormido;
    } else {
      _mood = GroguMood.feliz;
    }
  }

  void _ganarXP(int cantidad, {int esperarSegundos = 0}) {
  Future.delayed(Duration(seconds: esperarSegundos), () {
    _xp += cantidad;
    _checkLevelUp();
    _saveState();
    notifyListeners();
  });
}

  // Public method for mini game XP
  void ganarXPExterno(int cantidad) {
    _xp += cantidad;
    _felicidad = (_felicidad + 10).clamp(0, 100);
    _checkLevelUp();
    _saveState();
    notifyListeners();
  }

  void _checkLevelUp() {
    while (_xp >= _xpParaSiguienteNivel) {
      _xp = _xp - _xpParaSiguienteNivel;
      _nivel++;
      _xpParaSiguienteNivel = _nivel <= 10 ? 100 : 150;
      _subioDeNivel = true;
      _mood = GroguMood.muyFeliz;
      _sound.subirNivel();
    }
    if (_subioDeNivel) {
      Future.delayed(const Duration(seconds: 5), () {
        _subioDeNivel = false;
        _updateMood();
        notifyListeners();
      });
    }
  }

  void resetSubioDeNivel() {
    _subioDeNivel = false;
    notifyListeners();
  }

  void alimentar() {
    _hambre = (_hambre + 25).clamp(0, 100);
    _salud = (_salud + 5).clamp(0, 100);
    _mood = GroguMood.comiendo;
    _sound.comer();
    _ganarXP(10, esperarSegundos: 3);  // espera que termine comer
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _updateMood();
      notifyListeners();
    });
  }

  void jugar() {
    if (!puedeJugar) return;
    _felicidad = (_felicidad + 20).clamp(0, 100);
    _energia = (_energia - 10).clamp(0, 100);
    _mood = GroguMood.jugando;
    _sound.jugar();
    _ganarXP(15, esperarSegundos: 4);  // espera que termine jugar
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _mood = GroguMood.muyFeliz;
      _sound.celebrar();
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _updateMood();
        notifyListeners();
      });
    });
  }

  void dormir() {
    _energia = (_energia + 30).clamp(0, 100);
    _mood = GroguMood.dormido;
    _sound.dormir();
    _ganarXP(8, esperarSegundos: 4);
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _updateMood();
      notifyListeners();
    });
  }

  void banar() {
    _salud = (_salud + 20).clamp(0, 100);
    _felicidad = (_felicidad + 10).clamp(0, 100);
    _mood = GroguMood.muyFeliz;
    _sound.banar();
    _ganarXP(12, esperarSegundos: 3);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _updateMood();
      notifyListeners();
    });
  }

  void usarFuerza() {
    if (!puedeFuerza) return;
    _felicidad = (_felicidad + 15).clamp(0, 100);
    _mood = GroguMood.fuerza;
    _sound.fuerza();
    _ganarXP(20, esperarSegundos: 3);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _updateMood();
      notifyListeners();
    });
  }

  String get imagePath {
    String frame = _isAnimatingFrame2 ? '2' : '1';
    switch (_mood) {
      case GroguMood.feliz: return 'assets/images/grogu/Feliz_$frame.png';
      case GroguMood.cansado: return 'assets/images/grogu/Cansado_$frame.png';
      case GroguMood.dormido: return 'assets/images/grogu/Dormido_$frame.png';
      case GroguMood.hambriento: return 'assets/images/grogu/Hambriento_$frame.png';
      case GroguMood.comiendo: return 'assets/images/grogu/Comiendo_$frame.png';
      case GroguMood.jugando: return 'assets/images/grogu/Jugando_$frame.png';
      case GroguMood.triste: return 'assets/images/grogu/Triste_$frame.png';
      case GroguMood.enfermo: return 'assets/images/grogu/Enfermo_$frame.png';
      case GroguMood.muyFeliz: return 'assets/images/grogu/Feliz_$frame.png';
      case GroguMood.fuerza: return 'assets/images/grogu/Fuerza_$frame.png';
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hambre', _hambre);
    prefs.setDouble('felicidad', _felicidad);
    prefs.setDouble('energia', _energia);
    prefs.setDouble('salud', _salud);
    prefs.setInt('nivel', _nivel);
    prefs.setInt('xp', _xp);
    prefs.setInt('xpParaSiguienteNivel', _xpParaSiguienteNivel);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _hambre = prefs.getDouble('hambre') ?? 80.0;
    _felicidad = prefs.getDouble('felicidad') ?? 80.0;
    _energia = prefs.getDouble('energia') ?? 80.0;
    _salud = prefs.getDouble('salud') ?? 80.0;
    _nivel = prefs.getInt('nivel') ?? 1;
    _xp = prefs.getInt('xp') ?? 0;
    _xpParaSiguienteNivel = prefs.getInt('xpParaSiguienteNivel') ?? 100;
    _updateMood();
    notifyListeners();
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _decayTimer?.cancel();
    _sound.dispose();
    super.dispose();
  }
}
