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
  // ── Stats ──────────────────────────────────────────────
  double _hambre = 80.0;
  double _felicidad = 80.0;
  double _energia = 80.0;
  double _salud = 80.0;

  // ── Progreso ───────────────────────────────────────────
  int _nivel = 1;
  int _xp = 0;
  int _xpParaSiguienteNivel = 100;
  bool _subioDeNivel = false;
  bool _accionEnCurso = false;
  GroguMood _mood = GroguMood.feliz;
  bool _isAnimatingFrame2 = false;

  // ── Muerte ─────────────────────────────────────────────
  bool _groguMurio = false;
  int _contadorMuertes = 0;

  // ── Sesión diaria (10 min) ─────────────────────────────
  static const int kSesionSegundos = 600;
  int _segundosRestantes = kSesionSegundos;
  bool _sesionAgotada = false;
  bool _sesionIniciada = false;
  Timer? _sesionTimer;

  // ── Bono diario y racha ────────────────────────────────
  bool _bonoDiarioDisponible = false;
  int _rachaDias = 0;
  bool _bonoDiarioReclamado = false;

  // ── Timers internos ────────────────────────────────────
  Timer? _animTimer;
  Timer? _decayTimer;
  final SoundManager _sound = SoundManager();

  // ── Getters ────────────────────────────────────────────
  double get hambre => _hambre;
  double get felicidad => _felicidad;
  double get energia => _energia;
  double get salud => _salud;
  int get nivel => _nivel;
  int get xp => _xp;
  int get xpParaSiguienteNivel => _xpParaSiguienteNivel;
  double get xpProgress => _xp / _xpParaSiguienteNivel;
  bool get subioDeNivel => _subioDeNivel;
  bool get accionEnCurso => _accionEnCurso;
  GroguMood get mood => _mood;
  bool get isAnimatingFrame2 => _isAnimatingFrame2;
  bool get groguMurio => _groguMurio;
  int get contadorMuertes => _contadorMuertes;
  int get segundosRestantes => _segundosRestantes;
  bool get sesionAgotada => _sesionAgotada;
  bool get sesionIniciada => _sesionIniciada;
  bool get bonoDiarioDisponible => _bonoDiarioDisponible;
  bool get bonoDiarioReclamado => _bonoDiarioReclamado;
  int get rachaDias => _rachaDias;

  bool get enPeligro =>
      _hambre < 20 || _felicidad < 20 || _energia < 20 || _salud < 20;

  String? get baraEnPeligroCritico {
    if (_salud < 20) return 'Si no cuidas a Grogu... podría morir 💔';
    if (_hambre < 20) return 'Grogu tiene mucha hambre, ¡dale de comer! 🍽️';
    if (_energia < 20) return 'Grogu está agotado, ¡necesita dormir! 💤';
    if (_felicidad < 20) return 'Grogu está muy triste, ¡juega con él! 😢';
    return null;
  }

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

  // ── Constructor ────────────────────────────────────────
  GroguState() {
    _loadState();
    _startAnimation();
    _startDecay(); // decay siempre activo al abrir la app
  }

  void _startAnimation() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _isAnimatingFrame2 = !_isAnimatingFrame2;
      notifyListeners();
    });
  }

  void _startDecay() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_sesionAgotada) return;
      // +15% más rápido que antes (2.3, 1.15, 1.73)
      _hambre = (_hambre - 2.3).clamp(0, 100);
      _felicidad = (_felicidad - 1.15).clamp(0, 100);
      _energia = (_energia - 1.73).clamp(0, 100);
      if (_hambre < 20 || _energia < 20 || _felicidad < 20) {
        _salud = (_salud - 0.58).clamp(0, 100);
      }
      if (enPeligro) _sound.alerta();
      _updateMood();
      _saveState();
      if (_hambre <= 0 || _felicidad <= 0 || _energia <= 0 || _salud <= 0) {
        _triggerMuerte();
        return;
      }
      notifyListeners();
    });
  }

  // ── Sesión ─────────────────────────────────────────────
  void iniciarSesion() {
    if (_sesionIniciada || _sesionAgotada) return;
    _sesionIniciada = true;
    _sesionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes > 0) {
        _segundosRestantes--;
        notifyListeners();
      } else {
        _sesionAgotada = true;
        _sesionTimer?.cancel();
        _decayTimer?.cancel();
        _saveState();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _iniciarSesionSiNoIniciada() {
    if (!_sesionIniciada && !_sesionAgotada) iniciarSesion();
  }

  // ── Muerte ─────────────────────────────────────────────
  void _triggerMuerte() {
    _decayTimer?.cancel();
    _sesionTimer?.cancel();
    _contadorMuertes++;
    _groguMurio = true;
    _saveContadorMuertes();
    notifyListeners();
  }

  void confirmarMuerte() {
    _hambre = 80.0;
    _felicidad = 80.0;
    _energia = 80.0;
    _salud = 80.0;
    _nivel = 1;
    _xp = 0;
    _xpParaSiguienteNivel = 100;
    _subioDeNivel = false;
    _accionEnCurso = false;
    _groguMurio = false;
    _sesionAgotada = false;
    _sesionIniciada = false;
    _segundosRestantes = kSesionSegundos;
    _mood = GroguMood.feliz;
    _saveState();
    notifyListeners();
  }

  // ── Reset diario a medianoche ──────────────────────────
  Future<void> _checkResetDiario(SharedPreferences prefs) async {
    final ultimoDia = prefs.getString('ultimo_dia_sesion') ?? '';
    final hoy = _diaActual();
    if (ultimoDia != hoy) {
      _segundosRestantes = kSesionSegundos;
      _sesionAgotada = false;
      _sesionIniciada = false;
      _bonoDiarioReclamado = false;
      _bonoDiarioDisponible = true;
      if (ultimoDia.isNotEmpty && _fueAyer(ultimoDia)) {
        _rachaDias++;
      } else {
        _rachaDias = 1;
      }
      await prefs.setString('ultimo_dia_sesion', hoy);
      await prefs.setInt('racha_dias', _rachaDias);
      await prefs.setBool('bono_reclamado', false);
    } else {
      _rachaDias = prefs.getInt('racha_dias') ?? 1;
      _bonoDiarioReclamado = prefs.getBool('bono_reclamado') ?? false;
      _bonoDiarioDisponible = !_bonoDiarioReclamado;
    }
  }

  bool _fueAyer(String dia) {
    try {
      final parts = dia.split('-');
      final fecha = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      return fecha.year == ayer.year &&
          fecha.month == ayer.month &&
          fecha.day == ayer.day;
    } catch (_) {
      return false;
    }
  }

  int get xpBonoDiario => 20 + (_rachaDias * 5).clamp(0, 50);

  void reclamarBonoDiario() {
    if (!_bonoDiarioDisponible || _bonoDiarioReclamado) return;
    _bonoDiarioDisponible = false;
    _bonoDiarioReclamado = true;
    _xp += xpBonoDiario;
    _felicidad = (_felicidad + 15).clamp(0, 100);
    _checkLevelUp();
    _saveState();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('bono_reclamado', true));
    notifyListeners();
  }

  String _diaActual() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ── Mood ───────────────────────────────────────────────
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

  // ── XP ─────────────────────────────────────────────────
  void _ganarXP(int cantidad, {int esperarSegundos = 0}) {
    Future.delayed(Duration(seconds: esperarSegundos), () {
      _xp += cantidad;
      _checkLevelUp();
      _saveState();
      notifyListeners();
    });
  }

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

  // ── Acciones ───────────────────────────────────────────
  void alimentar() {
    _iniciarSesionSiNoIniciada();
    if (_sesionAgotada) return;
    _hambre = (_hambre + 25).clamp(0, 100);
    _salud = (_salud + 5).clamp(0, 100);
    _mood = GroguMood.comiendo;
    _accionEnCurso = true;
    _sound.comer();
    _ganarXP(10, esperarSegundos: 3);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _accionEnCurso = false;
      _updateMood();
      notifyListeners();
    });
  }

  void jugar() {
    if (!puedeJugar) return;
    _iniciarSesionSiNoIniciada();
    if (_sesionAgotada) return;
    _felicidad = (_felicidad + 20).clamp(0, 100);
    _energia = (_energia - 10).clamp(0, 100);
    _mood = GroguMood.jugando;
    _accionEnCurso = true;
    _sound.jugar();
    _ganarXP(15, esperarSegundos: 4);
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _mood = GroguMood.muyFeliz;
      _sound.celebrar();
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _accionEnCurso = false;
        _updateMood();
        notifyListeners();
      });
    });
  }

  void dormir() {
    _iniciarSesionSiNoIniciada();
    if (_sesionAgotada) return;
    _energia = (_energia + 30).clamp(0, 100);
    _mood = GroguMood.dormido;
    _accionEnCurso = true;
    _sound.dormir();
    _ganarXP(8, esperarSegundos: 4);
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () {
      _accionEnCurso = false;
      _updateMood();
      notifyListeners();
    });
  }

  void banar() {
    _iniciarSesionSiNoIniciada();
    if (_sesionAgotada) return;
    _salud = (_salud + 20).clamp(0, 100);
    _felicidad = (_felicidad + 10).clamp(0, 100);
    _mood = GroguMood.muyFeliz;
    _accionEnCurso = true;
    _sound.banar();
    _ganarXP(12, esperarSegundos: 3);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _accionEnCurso = false;
      _updateMood();
      notifyListeners();
    });
  }

  void usarFuerza() {
    if (!puedeFuerza) return;
    _iniciarSesionSiNoIniciada();
    if (_sesionAgotada) return;
    _felicidad = (_felicidad + 15).clamp(0, 100);
    _mood = GroguMood.fuerza;
    _accionEnCurso = true;
    _sound.fuerza();
    _ganarXP(20, esperarSegundos: 3);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _accionEnCurso = false;
      _updateMood();
      notifyListeners();
    });
  }

  // ── imagePath ──────────────────────────────────────────
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

  // ── Persistencia ───────────────────────────────────────
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('hambre', _hambre);
    prefs.setDouble('felicidad', _felicidad);
    prefs.setDouble('energia', _energia);
    prefs.setDouble('salud', _salud);
    prefs.setInt('nivel', _nivel);
    prefs.setInt('xp', _xp);
    prefs.setInt('xpParaSiguienteNivel', _xpParaSiguienteNivel);
    prefs.setInt('segundos_restantes', _segundosRestantes);
    prefs.setBool('sesion_agotada', _sesionAgotada);
    prefs.setString('ultimo_dia_sesion', _diaActual());
  }

  Future<void> _saveContadorMuertes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('contador_muertes', _contadorMuertes);
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
    _contadorMuertes = prefs.getInt('contador_muertes') ?? 0;
    _segundosRestantes = prefs.getInt('segundos_restantes') ?? kSesionSegundos;
    _sesionAgotada = prefs.getBool('sesion_agotada') ?? false;
    await _checkResetDiario(prefs);
    _updateMood();
    notifyListeners();
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _decayTimer?.cancel();
    _sesionTimer?.cancel();
    _sound.dispose();
    super.dispose();
  }
}
