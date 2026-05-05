import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/grogu_state.dart';
import '../widgets/stats_bar.dart';
import '../widgets/xp_toast.dart';
import 'arcade_menu_screen.dart';
import 'grogu_death_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroguState(),
      child: const _GameScreenBody(),
    );
  }
}

class _GameScreenBody extends StatefulWidget {
  const _GameScreenBody();

  @override
  State<_GameScreenBody> createState() => _GameScreenBodyState();
}

class _GameScreenBodyState extends State<_GameScreenBody>
    with TickerProviderStateMixin {
  late AnimationController _levelUpController;
  late Animation<double> _levelUpAnim;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  GroguMood? _lastMood;

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _levelUpAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _checkLevelUp(GroguState grogu) {
    if (grogu.subioDeNivel) {
      _levelUpController.forward(from: 0);
      grogu.resetSubioDeNivel();
    }
    // Bounce al cambiar de mood (acción ejecutada)
    if (_lastMood != grogu.mood) {
      _lastMood = grogu.mood;
      _bounceController.forward(from: 0).then((_) => _bounceController.reverse());
    }
  }

  void _openArcade(BuildContext context, GroguState grogu) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ArcadeMenuScreen(grogu: grogu),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grogu = context.watch<GroguState>();
    _checkLevelUp(grogu);

    // Navegar a pantalla de muerte
    if (grogu.groguMurio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const GroguDeathScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      });
    }

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
          child: Stack(
            children: [
              Column(
                children: [
                  // Title + settings button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 36),
                        const Expanded(
                          child: Text(
                            '✨ May the Fabi be with you ✨',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.orange, blurRadius: 8)
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openSettings(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings,
                                color: Colors.white60, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Level bar
                  _buildLevelBar(grogu),
                  const SizedBox(height: 4),

                  // Timer de sesión — siempre visible
                  if (!grogu.sesionAgotada)
                    _buildSessionTimer(grogu)
                  else
                    _buildSessionTimer(grogu),

                  // Aviso de peligro
                  if (grogu.baraEnPeligroCritico != null && !grogu.sesionAgotada)
                    _buildPeligroAviso(grogu.baraEnPeligroCritico!),

                  // Stats
                  StatsBar(
                    label: 'Hambre',
                    value: grogu.hambre,
                    color: Colors.orange,
                    iconPath: 'assets/images/ui/bowl_food.png',
                  ),
                  StatsBar(
                    label: 'Felicidad',
                    value: grogu.felicidad,
                    color: Colors.pink,
                    iconPath: 'assets/images/ui/cute_heart.png',
                  ),
                  StatsBar(
                    label: 'Energía',
                    value: grogu.energia,
                    color: Colors.purple,
                    iconPath: 'assets/images/ui/sleepy_moon.png',
                  ),
                  StatsBar(
                    label: 'Salud',
                    value: grogu.salud,
                    color: Colors.green,
                    iconPath: 'assets/images/ui/cute_star.png',
                  ),

                  const SizedBox(height: 4),

                  // Grogu
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: grogu.groguSize + 60,
                            height: grogu.groguSize + 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _getEtapaColor(grogu.etapa)
                                      .withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _bounceAnim,
                            builder: (_, child) => Transform.scale(
                              scale: _bounceAnim.value,
                              child: child,
                            ),
                            child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.85, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: grogu.groguSize,
                              height: grogu.groguSize,
                              child: Image.asset(
                                grogu.imagePath,
                                key: ValueKey(grogu.imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          ), // cierre AnimatedBuilder bounce
                        ],
                      ),
                    ),
                  ),

                  // Mood
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _getMoodText(grogu.mood),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // Bono diario
                  if (grogu.bonoDiarioDisponible)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: GestureDetector(
                        onTap: () {
                          grogu.reclamarBonoDiario();
                          XpToast.show(
                            context,
                            '+${grogu.xpBonoDiario} XP Bono',
                            color: Colors.amber,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.2),
                                Colors.orange.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.25),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎁', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Bono diario! +${grogu.xpBonoDiario} XP',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (grogu.rachaDias > 1)
                                    Text(
                                      '🔥 Racha: ${grogu.rachaDias} días',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Arcade button
                  if (grogu.nivel >= 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: GestureDetector(
                        onTap: () => _openArcade(context, grogu),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1a0a3e),
                                Color(0xFF0d1b4b),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🕹️', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 8),
                              Text(
                                'Arcade',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Arcade unlock hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      grogu.nivel < 3
                          ? '🔒 Arcade se desbloquea en nivel 3'
                          : grogu.nivel < 6
                              ? '🧱 Tetris disponible en nivel 6'
                              : '🏆 Todos los juegos desbloqueados',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          imagePath: 'assets/images/ui/cute_bowl.png',
                          label: 'Comer',
                          onTap: grogu.alimentar,
                          color: Colors.orange,
                          locked: grogu.accionEnCurso,
                          xp: '+10 XP',
                        ),
                        _ActionButton(
                          imagePath:
                              'assets/images/ui/cute_controller_game.png',
                          label: 'Jugar',
                          onTap: grogu.jugar,
                          color: Colors.purple,
                          locked: grogu.accionEnCurso || !grogu.puedeJugar,
                          xp: '+15 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/sleepy_moon.png',
                          label: 'Dormir',
                          onTap: grogu.dormir,
                          color: Colors.indigo,
                          locked: grogu.accionEnCurso,
                          xp: '+8 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/small_bath.png',
                          label: 'Bañar',
                          onTap: grogu.banar,
                          color: Colors.cyan,
                          locked: grogu.accionEnCurso,
                          xp: '+12 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/cute_frog.png',
                          label: 'Fuerza',
                          onTap: grogu.usarFuerza,
                          color: Colors.green,
                          locked: grogu.accionEnCurso || !grogu.puedeFuerza,
                          xp: '+20 XP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),

              // Level up overlay
              if (_levelUpController.isAnimating ||
                  _levelUpController.value > 0)
                _buildLevelUpOverlay(grogu),

              // Overlay sesión agotada
              if (grogu.sesionAgotada)
                _buildSesionAgotadaOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTimer(GroguState grogu) {
    final mins = grogu.segundosRestantes ~/ 60;
    final secs = grogu.segundosRestantes % 60;
    final isUrgente = grogu.sesionIniciada && grogu.segundosRestantes <= 60;
    final isAgotada = grogu.sesionAgotada;

    String texto;
    Color color;
    IconData icono;

    if (isAgotada) {
      texto = 'Tiempo agotado — vuelve mañana 🌙';
      color = Colors.white38;
      icono = Icons.lock_clock;
    } else if (!grogu.sesionIniciada) {
      texto = 'Tienes 10 min hoy — ¡toca algo para empezar! ⏱️';
      color = Colors.white38;
      icono = Icons.timer_outlined;
    } else {
      texto = 'Tiempo hoy: ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      color = isUrgente ? Colors.redAccent : Colors.white54;
      icono = Icons.timer;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isUrgente ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeligroAviso(String mensaje) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionAgotadaOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Tu tiempo con Grogu\nterminó por hoy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Así como Grogu necesita descanso,\ntú también. Vuelve mañana 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'El juego se desbloqueará a medianoche ✨',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBar(GroguState grogu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                grogu.etapaNombre,
                style: TextStyle(
                  color: _getEtapaColor(grogu.etapa),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nivel ${grogu.nivel}  •  ${grogu.xp}/${grogu.xpParaSiguienteNivel} XP',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                widthFactor: grogu.xpProgress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getEtapaColor(grogu.etapa),
                        _getEtapaColor(grogu.etapa).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getEtapaColor(grogu.etapa).withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpOverlay(GroguState grogu) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _levelUpAnim,
          builder: (_, __) {
            final opacity = _levelUpController.value < 0.5
                ? _levelUpController.value * 2
                : (1 - _levelUpController.value) * 2;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Transform.scale(
                    scale: _levelUpAnim.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '⭐ ¡SUBISTE DE NIVEL! ⭐',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.orange, blurRadius: 16)
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nivel ${grogu.nivel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          grogu.etapaNombre,
                          style: TextStyle(
                            color: _getEtapaColor(grogu.etapa),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (grogu.nivel == 3 || grogu.nivel == 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.purpleAccent.withOpacity(0.5)),
                              ),
                              child: Text(
                                grogu.nivel == 3
                                    ? '🕹️ ¡Arcade desbloqueado!'
                                    : '🧱 ¡Tetris Galáctico desbloqueado!',
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        if (grogu.etapa == GroguEtapa.aprendiz &&
                            grogu.nivel == 11)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '🎮 ¡Jugar y Fuerza desbloqueados!',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        // Eventos por nivel clave (#10)
                        if (_getMensajeNivel(grogu.nivel) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: Text(
                                _getMensajeNivel(grogu.nivel)!,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getEtapaColor(GroguEtapa etapa) {
    switch (etapa) {
      case GroguEtapa.bebe: return Colors.greenAccent;
      case GroguEtapa.aprendiz: return Colors.amber;
      case GroguEtapa.maestro: return Colors.purpleAccent;
    }
  }

  String? _getMensajeNivel(int nivel) {
    switch (nivel) {
      case 5: return '✨ "Así como cuidas a Grogu,\ncuídate a ti misma cada día." 💚';
      case 10: return '🌟 "10 niveles de constancia.\nEres increíble, Fabi." 🥹';
      case 15: return '💫 "La fuerza está contigo,\ny también la constancia." ⭐';
      case 20: return '🔮 "20 niveles. Grogu te ama\ntanto como yo te aprecio." 💜';
      case 25: return '🚀 "Eres Grogu Maestra. Nada\nte detiene cuando te propones algo." 🌙';
      default: return null;
    }
  }

  String _getMoodText(GroguMood mood) {
    switch (mood) {
      case GroguMood.feliz: return '😊 Grogu está feliz';
      case GroguMood.cansado: return '😪 Grogu está cansado...';
      case GroguMood.dormido: return '😴 Grogu está dormido... zzz';
      case GroguMood.hambriento: return '🍽️ ¡Grogu tiene hambre!';
      case GroguMood.comiendo: return '😋 Grogu está comiendo~';
      case GroguMood.jugando: return '🎮 ¡Grogu está jugando!';
      case GroguMood.triste: return '😢 Grogu está triste...';
      case GroguMood.enfermo: return '😷 Grogu no se siente bien';
      case GroguMood.muyFeliz: return '🎉 ¡Grogu está muy feliz!';
      case GroguMood.fuerza: return '🔮 Grogu usa la Fuerza...';
    }
  }
}

class _ActionButton extends StatefulWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool locked;
  final String xp;

  const _ActionButton({
    required this.imagePath,
    required this.label,
    required this.onTap,
    required this.color,
    required this.locked,
    required this.xp,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.locked) return;
    _scaleController.forward().then((_) => _scaleController.reverse());
    HapticFeedback.lightImpact();
    widget.onTap();
    // Mostrar toast de XP
    XpToast.show(
      context,
      widget.xp,
      color: widget.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Opacity(
        opacity: widget.locked ? 0.4 : 1.0,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: widget.color.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: widget.color.withOpacity(0.2), blurRadius: 8),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  if (widget.locked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black45,
                        ),
                        child: const Icon(Icons.lock,
                            color: Colors.white54, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.locked ? Colors.white38 : widget.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.xp,
                style: TextStyle(
                  color: widget.locked ? Colors.white24 : Colors.amber,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
