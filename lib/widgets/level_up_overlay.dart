import 'dart:math';
import 'package:flutter/material.dart';

class LevelUpOverlay extends StatefulWidget {
  final int nivel;

  const LevelUpOverlay({
    super.key,
    required this.nivel,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {

  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;

  late Animation<double> _scale;
  late Animation<double> _fade;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_updateParticles);

    _scale = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _initParticles();
    _startAnimation();
  }

  void _initParticles() {
    final rand = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          x: rand.nextDouble(),
          y: rand.nextDouble() * -0.3,
          speed: rand.nextDouble() * 0.015 + 0.005,
          size: rand.nextDouble() * 6 + 3,
          color: Colors.primaries[rand.nextInt(Colors.primaries.length)],
        ),
      );
    }
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.y += p.speed;
      if (p.y > 1.2) p.y = -0.2;
    }
    setState(() {});
  }

  void _startAnimation() async {
    _confettiController.repeat();
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _fadeController.forward();
  }

  String _mensaje() {
    if (widget.nivel == 1) return "🌱 Empieza la aventura";
    if (widget.nivel == 5) return "💖 Fabi, esto es para ti";
    if (widget.nivel == 10) return "🌟 Ya estás creciendo mucho";
    if (widget.nivel == 20) return "🚀 Imparable";
    return "✨ Sigue así";
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.85)),
            CustomPaint(
              painter: _ConfettiPainter(_particles),
              size: Size.infinite,
            ),
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(_fade),
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("✨", style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      const Text(
                        "LEVEL UP",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFFF00),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Nivel ${widget.nivel}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4FC3F7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mensaje(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}