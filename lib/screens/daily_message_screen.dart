import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_message.dart';
import '../models/sound_manager.dart';
import 'game_screen.dart';

class DailyMessageScreen extends StatefulWidget {
  const DailyMessageScreen({super.key});

  @override
  State<DailyMessageScreen> createState() => _DailyMessageScreenState();
}

class _DailyMessageScreenState extends State<DailyMessageScreen>
    with TickerProviderStateMixin {
  late AnimationController _groguController;
  late AnimationController _bubbleController;
  late AnimationController _glowController;
  late Animation<double> _groguScale;
  late Animation<double> _groguSlide;
  late Animation<double> _bubbleAnim;
  bool _showBubble = false;
  bool _frame2 = false;
  String _frase = '';
  bool _esCumple = false;

  final SoundManager _sound = SoundManager();

  @override
  void initState() {
    super.initState();

    _groguController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _groguScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _groguController, curve: Curves.elasticOut),
    );
    _groguSlide = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _groguController, curve: Curves.easeOut),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bubbleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.elasticOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sound.musicaFrase();
    _loadFrase();

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _frame2 = !_frame2);
      return mounted;
    });
  }

  Future<void> _loadFrase() async {
    final frase = await DailyMessage.getFraseDelDia();
    final esCumple = DailyMessage.esCumpleanos();

    // Save today's date so we don't show again today
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ultimaFechaFrase',
      DateTime.now().toIso8601String(),
    );

    if (mounted) {
      setState(() {
        _frase = frase;
        _esCumple = esCumple;
      });
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _groguController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              setState(() => _showBubble = true);
              _bubbleController.forward();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _groguController.dispose();
    _bubbleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _continuar() {
    _sound.stopMusica();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a2e),
              Color(0xFF1a0a3e),
              Color(0xFF0d1b4b),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_esCumple) ...[
                const Text(
                  '🎂 ¡Feliz Cumpleaños! 🎂',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.orange, blurRadius: 12)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],

              const Text(
                '✨ May the Fabi be with you ✨',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  shadows: [Shadow(color: Colors.orange, blurRadius: 8)],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              AnimatedBuilder(
                animation: _groguController,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _groguSlide.value),
                  child: Transform.scale(
                    scale: _groguScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (_, __) => Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.greenAccent.withOpacity(
                                      0.1 + 0.15 * _glowController.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/grogu/Feliz_${_frame2 ? "2" : "1"}.png',
                          width: 180,
                          height: 180,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_showBubble && _frase.isNotEmpty)
                ScaleTransition(
                  scale: _bubbleAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: -12,
                          child: CustomPaint(
                            painter: _BubbleTailPainter(),
                            size: const Size(24, 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            _frase,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _esCumple ? 15 : 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2a1a4e),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 36),

              if (_showBubble)
                ScaleTransition(
                  scale: _bubbleAnim,
                  child: GestureDetector(
                    onTap: _continuar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Text(
                        '¡Gracias Grogu! 💚',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
