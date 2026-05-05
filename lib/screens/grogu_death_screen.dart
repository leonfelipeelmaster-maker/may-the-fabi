import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grogu_state.dart';

class GroguDeathScreen extends StatefulWidget {
  const GroguDeathScreen({super.key});

  @override
  State<GroguDeathScreen> createState() => _GroguDeathScreenState();
}

class _GroguDeathScreenState extends State<GroguDeathScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _shakeAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Detener el shake después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _shakeController.stop();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grogu = context.watch<GroguState>();

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0a0014),
                Color(0xFF1a0020),
                Color(0xFF0a000a),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Grogu triste con shake
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Image.asset(
                          'assets/images/grogu/Triste_1.png',
                          width: 160,
                          height: 160,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Título
                    const Text(
                      '💔 Grogu se fue...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Mensaje emotivo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Grogu necesitaba tu cuidado y no llegaste a tiempo... '
                        'Así como él, a veces nosotros también necesitamos atención diaria. '
                        'Vuelve mañana y cuídalo mejor. 🌟',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contador de muertes
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💀', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            grogu.contadorMuertes == 1
                                ? 'Esta es la primera vez que Grogu muere'
                                : 'Grogu ha muerto ${grogu.contadorMuertes} veces',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón de reinicio
                    GestureDetector(
                      onTap: () {
                        grogu.confirmarMuerte();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4FC3F7),
                              Color(0xFFBB00FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🌱 Darle una nueva oportunidad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'El progreso se reiniciará desde el principio',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
