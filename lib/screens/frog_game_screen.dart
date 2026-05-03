import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sound_manager.dart';

class FrogGameScreen extends StatefulWidget {
  final int nivelJuego;
  final Function(int xpGanado) onGameOver;

  const FrogGameScreen({
    super.key,
    required this.nivelJuego,
    required this.onGameOver,
  });

  @override
  State<FrogGameScreen> createState() => _FrogGameScreenState();
}

class _FrogGameScreenState extends State<FrogGameScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  final SoundManager _sound = SoundManager();

  List<FrogEntity> _frogs = [];
  int _score = 0;
  int _xpGanado = 0;
  int _vidas = 3;
  int _ranasAtrapadas = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  Timer? _spawnTimer;
  Timer? _gameTimer;
  int _timeLeft = 60;
  bool _groguFrame2 = false;

  late AnimationController _groguController;
  late AnimationController _countdownController;

  // Config by nivel
  late double _velocidadBase;
  late int _maxRanas;
  late bool _ranasDoradas;
  late bool _ranasFalsas;
  late int _xpPorRana;
  late int _vidasIniciales;
  late Duration _spawnInterval;

  @override
  void initState() {
    super.initState();

    _groguController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _setupNivel();

    // Animate Grogu frames
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _groguFrame2 = !_groguFrame2);
      return mounted;
    });

    _startCountdown();
  }

  void _setupNivel() {
  switch (widget.nivelJuego) {
    case 1:
      _velocidadBase = 0.8;
      _maxRanas = 1;
      _ranasDoradas = false;
      _ranasFalsas = false;
      _xpPorRana = 5;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(seconds: 4);
      break;
    case 2:
      _velocidadBase = 1.0;
      _maxRanas = 1;
      _ranasDoradas = false;
      _ranasFalsas = false;
      _xpPorRana = 5;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(milliseconds: 3500);
      break;
    case 3:
      _velocidadBase = 1.2;
      _maxRanas = 2;
      _ranasDoradas = false;
      _ranasFalsas = false;
      _xpPorRana = 8;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(seconds: 3);
      break;
    case 4:
      _velocidadBase = 1.4;
      _maxRanas = 2;
      _ranasDoradas = true;
      _ranasFalsas = false;
      _xpPorRana = 8;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(milliseconds: 2800);
      break;
    case 5:
      _velocidadBase = 1.6;
      _maxRanas = 3;
      _ranasDoradas = true;
      _ranasFalsas = false;
      _xpPorRana = 12;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(milliseconds: 2500);
      break;
    case 6:
      _velocidadBase = 1.8;
      _maxRanas = 3;
      _ranasDoradas = true;
      _ranasFalsas = true;
      _xpPorRana = 12;
      _vidasIniciales = 3;
      _spawnInterval = const Duration(milliseconds: 2200);
      break;
    default:
      _velocidadBase = 2.0;
      _maxRanas = 4;
      _ranasDoradas = true;
      _ranasFalsas = true;
      _xpPorRana = 20;
      _vidasIniciales = 2;
      _spawnInterval = const Duration(milliseconds: 2000);
      break;
  }
  _vidas = _vidasIniciales;
}
  void _startCountdown() {
    _countdownController.forward().then((_) {
      if (mounted) {
        setState(() => _gameStarted = true);
        _startGame();
      }
    });
  }

  void _startGame() {
    // Spawn frogs
    _spawnTimer = Timer.periodic(_spawnInterval, (_) {
      if (!_gameOver && _frogs.length < _maxRanas) {
        _spawnFrog();
      }
    });

    // Game countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameOver) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) _endGame();
      }
    });

    // Move frogs
    Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _gameOver) return;
      setState(() {
        _frogs = _frogs.map((f) {
          f.y += f.speed;
          return f;
        }).toList();

        // Check escaped frogs
        final escaped = _frogs.where((f) => f.y > 1.1).toList();
        for (final f in escaped) {
          if (!f.isDorada && !f.isFalsa) {
            _vidas--;
            HapticFeedback.vibrate();
            if (_vidas <= 0) _endGame();
          }
        }
        _frogs.removeWhere((f) => f.y > 1.1);
      });
    });
  }

  void _spawnFrog() {
    final isFalsa = _ranasFalsas && _random.nextDouble() < 0.2;
    final isDorada = !isFalsa && _ranasDoradas && _random.nextDouble() < 0.15;

    // Speed increases every 10 frogs caught
    final speedBonus = (_ranasAtrapadas ~/ 10) * 0.5;
    final speed = (_velocidadBase + speedBonus + _random.nextDouble() * 0.5)
        / 100;

    setState(() {
      _frogs.add(FrogEntity(
        id: DateTime.now().millisecondsSinceEpoch +
            _random.nextInt(1000),
        x: 0.1 + _random.nextDouble() * 0.8,
        y: -0.1,
        speed: speed,
        isDorada: isDorada,
        isFalsa: isFalsa,
      ));
    });
  }

  void _onFrogTap(FrogEntity frog) {
    if (_gameOver) return;

    if (frog.isFalsa) {
      // Penalty for tapping false frog
      _vidas--;
      HapticFeedback.vibrate();
      _sound.alerta();
      setState(() => _frogs.remove(frog));
      if (_vidas <= 0) _endGame();
      return;
    }

    // Caught a real frog!
    HapticFeedback.lightImpact();
    _sound.jugar();

    final puntos = frog.isDorada ? _xpPorRana * 2 : _xpPorRana;
    final score = frog.isDorada ? 20 : 10;

    setState(() {
      _frogs.remove(frog);
      _ranasAtrapadas++;
      _score += score;
      _xpGanado += puntos;
    });
  }

  void _endGame() {
    setState(() => _gameOver = true);
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    _sound.celebrar();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    _groguController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a2e),
              Color(0xFF0d1b4b),
              Color(0xFF1a3a1a),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Stars background
              CustomPaint(
                painter: _StarsBgPainter(),
                size: Size.infinite,
              ),

              // Game UI
              if (!_gameOver) ...[
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(),
                ),

                // Frogs
                ..._frogs.map((frog) => _buildFrog(frog, size)),

                // Grogu at bottom
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/grogu/Feliz_${_groguFrame2 ? "2" : "1"}.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),

                // Countdown overlay
                if (!_gameStarted)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _countdownController,
                          builder: (_, __) {
                            final val = (1 - _countdownController.value);
                            final count = (val * 3).ceil();
                            return Text(
                              count > 0 ? '$count' : '¡Ya!',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                      color: Colors.orange, blurRadius: 20)
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],

              // Game Over screen
              if (_gameOver) _buildGameOver(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lives
          Row(
            children: List.generate(
              _vidasIniciales,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Image.asset(
                  'assets/images/ui/cute_heart.png',
                  width: 28,
                  height: 28,
                  color: i < _vidas ? null : Colors.grey,
                  colorBlendMode: i < _vidas ? null : BlendMode.saturation,
                ),
              ),
            ),
          ),

          // Score
          Column(
            children: [
              Text(
                '🐸 $_ranasAtrapadas',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+$_xpGanado XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Timer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _timeLeft <= 10
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _timeLeft <= 10 ? Colors.red : Colors.white24,
              ),
            ),
            child: Text(
              '⏱ $_timeLeft',
              style: TextStyle(
                color: _timeLeft <= 10 ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrog(FrogEntity frog, Size size) {
    final left = frog.x * size.width - 35;
    final top = frog.y * size.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onFrogTap(frog),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (frog.isDorada)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ColorFiltered(
              colorFilter: frog.isDorada
                  ? const ColorFilter.matrix([
                      1.5, 0.5, 0, 0, 0,
                      0.5, 1.2, 0, 0, 0,
                      0, 0, 0.3, 0, 0,
                      0, 0, 0, 1, 0,
                    ])
                  : frog.isFalsa
                      ? const ColorFilter.matrix([
                          0.3, 0, 0, 0, 0,
                          0, 0.3, 0, 0, 0,
                          0.8, 0, 1.2, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.matrix([
                          1, 0, 0, 0, 0,
                          0, 1, 0, 0, 0,
                          0, 0, 1, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
              child: Image.asset(
                'assets/images/ui/cute_frog.png',
                width: 65,
                height: 65,
              ),
            ),
            if (frog.isFalsa)
              const Positioned(
                top: 0,
                right: 0,
                child: Text('💀', style: TextStyle(fontSize: 16)),
              ),
            if (frog.isDorada)
              const Positioned(
                top: 0,
                right: 0,
                child: Text('⭐', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a4e), Color(0xFF0d2d0d)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/grogu/Feliz_1.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 12),
            const Text(
              '🎉 ¡Juego terminado!',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _statRow('🐸 Ranas atrapadas', '$_ranasAtrapadas'),
            _statRow('⭐ Puntuación', '$_score'),
            _statRow('💚 XP ganado', '+$_xpGanado XP'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _gameOverButton(
                  '🔄 Repetir',
                  Colors.blue,
                  () {
                    widget.onGameOver(_xpGanado);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => FrogGameScreen(
                          nivelJuego: widget.nivelJuego,
                          onGameOver: widget.onGameOver,
                        ),
                      ),
                    );
                  },
                ),
                _gameOverButton(
                  '🏠 Volver',
                  Colors.green,
                  () {
                    widget.onGameOver(_xpGanado);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _gameOverButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class FrogEntity {
  final int id;
  final double x;
  double y;
  final double speed;
  final bool isDorada;
  final bool isFalsa;

  FrogEntity({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
    required this.isDorada,
    required this.isFalsa,
  });
}

class _StarsBgPainter extends CustomPainter {
  static final List<Offset> _stars = [];
  static bool _initialized = false;

  _StarsBgPainter() {
    if (!_initialized) {
      final r = Random(99);
      for (int i = 0; i < 80; i++) {
        _stars.add(Offset(r.nextDouble(), r.nextDouble()));
      }
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    for (final s in _stars) {
      canvas.drawCircle(
          Offset(s.dx * size.width, s.dy * size.height), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
