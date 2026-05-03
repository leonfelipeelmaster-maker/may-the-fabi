import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_manager.dart';
import 'daily_message_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  int _stage = 0;

  late AnimationController _shakeController;
  late AnimationController _confettiController;
  late AnimationController _shipController;
  late AnimationController _groguController;
  late AnimationController _textController;
  late AnimationController _starsController;
  late AnimationController _glowController;

  late Animation<double> _shakeAnim;
  late Animation<double> _shipAnim;
  late Animation<double> _groguScaleAnim;
  late Animation<double> _groguSlideAnim;
  late Animation<double> _textAnim;

  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _frame2 = false;

  final SoundManager _sound = SoundManager();

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _shipAnim = Tween<double>(begin: -350, end: 0).animate(
      CurvedAnimation(parent: _shipController, curve: Curves.easeOut),
    );

    _groguController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _groguScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _groguController, curve: Curves.elasticOut),
    );
    _groguSlideAnim = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _groguController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    for (int i = 0; i < 80; i++) {
      _particles.add(ConfettiParticle(random: _random));
    }

    _shakeController.repeat(reverse: true);
    HapticFeedback.vibrate();

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _frame2 = !_frame2);
      return mounted;
    });
  }

  Future<void> _goToDailyMessage() async {
    // Save that intro has been seen — never show again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('yaVioIntro', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DailyMessageScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onBoxTap() {
    if (_stage == 0) {
      HapticFeedback.heavyImpact();
      _sound.regalo();

      setState(() => _stage = 1);
      _shakeController.stop();
      _confettiController.forward();
      _textController.forward();

      // Wait for regalo.mp3 to finish (16 seconds) then go to space
      Future.delayed(const Duration(seconds: 16), () {
        if (mounted) {
          setState(() => _stage = 2);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _sound.nave();
              _shipController.forward().then((_) {
                HapticFeedback.mediumImpact();
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) {
                    setState(() => _stage = 3);
                    _sound.aparece();
                    HapticFeedback.lightImpact();
                    _groguController.forward().then((_) {
                      Future.delayed(const Duration(seconds: 3), () {
                        _goToDailyMessage();
                      });
                    });
                  }
                });
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
    _shipController.dispose();
    _groguController.dispose();
    _textController.dispose();
    _starsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildStarfield(),
          if (_stage == 0) _buildClosedBox(),
          if (_stage == 1) _buildOpenBox(),
          if (_stage >= 2) _buildSpaceScene(size),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return AnimatedBuilder(
      animation: _starsController,
      builder: (_, __) => CustomPaint(
        painter: StarfieldPainter(_starsController.value),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildClosedBox() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡Toca la caja! 🎁',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: GestureDetector(
              onTap: _onBoxTap,
              child: Image.asset(
                'assets/images/intro/caja-sorpresa.png',
                width: 220,
                height: 220,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenBox() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _confettiController,
          builder: (_, __) => CustomPaint(
            painter: ConfettiPainter(_particles, _confettiController.value),
            size: Size.infinite,
          ),
        ),
        Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(
          child: FadeTransition(
            opacity: _textAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_textController),
              child: Image.asset(
                'assets/images/intro/caja_feliz_cumple.png',
                width: 320,
                height: 320,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceScene(Size size) {
    final shipTop = size.height * 0.18;
    final groguTop = size.height * 0.42;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _shipAnim,
          builder: (_, child) => Positioned(
            top: shipTop + _shipAnim.value,
            left: 0,
            right: 0,
            child: Center(child: child!),
          ),
          child: Image.asset(
            'assets/images/intro/nave_grogu.png',
            width: 260,
            height: 260,
          ),
        ),

        if (_stage >= 2)
          AnimatedBuilder(
            animation: _shipController,
            builder: (_, __) {
              final progress = _shipController.value;
              if (progress < 0.85) return const SizedBox();
              final opacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
              return Positioned(
                top: shipTop + 220,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 180,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.35 * opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        if (_stage == 3)
          Positioned(
            top: groguTop,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _groguController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _groguSlideAnim.value),
                  child: Transform.scale(
                    scale: _groguScaleAnim.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (_, __) => Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.greenAccent.withOpacity(
                                      0.1 + 0.12 * _glowController.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/grogu/Feliz_${_frame2 ? "2" : "1"}.png',
                          width: 170,
                          height: 170,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (_stage == 3)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _groguScaleAnim,
              child: const Text(
                '✨ May the Fabi be with you ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.orange, blurRadius: 12)],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StarfieldPainter extends CustomPainter {
  final double animValue;
  static final List<Offset> _stars = [];
  static final List<double> _sizes = [];
  static bool _initialized = false;

  StarfieldPainter(this.animValue) {
    if (!_initialized) {
      final random = Random(42);
      for (int i = 0; i < 120; i++) {
        _stars.add(Offset(
          random.nextDouble() * 400,
          random.nextDouble() * 900,
        ));
        _sizes.add(random.nextDouble() * 2.5 + 0.5);
      }
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < _stars.length; i++) {
      final opacity = 0.4 + 0.6 * sin(animValue * pi + i * 0.5).abs();
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(
          _stars[i].dx / 400 * size.width,
          _stars[i].dy / 900 * size.height,
        ),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.animValue != animValue;
}

class ConfettiParticle {
  late double x, y, vx, vy, size, rotation, rotSpeed;
  late Color color;

  ConfettiParticle({required Random random}) {
    x = random.nextDouble();
    y = random.nextDouble() * -0.5;
    vx = (random.nextDouble() - 0.5) * 0.3;
    vy = random.nextDouble() * 0.4 + 0.2;
    size = random.nextDouble() * 12 + 5;
    rotation = random.nextDouble() * pi * 2;
    rotSpeed = (random.nextDouble() - 0.5) * 0.2;
    final colors = [
      Colors.pink, Colors.purple, Colors.yellow,
      Colors.cyan, Colors.orange, Colors.green, Colors.red,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final x = (p.x + p.vx * progress * 3) * size.width;
      final y = (p.y + p.vy * progress * 2) * size.height;
      final opacity = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
      paint.color = p.color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotSpeed * progress * 10);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.progress != progress;
}
