import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grogu_state.dart';
import '../widgets/stats_bar.dart';
import 'arcade_menu_screen.dart';
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
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
  }

  void _checkLevelUp(GroguState grogu) {
    if (grogu.subioDeNivel) {
      _levelUpController.forward(from: 0);
      grogu.resetSubioDeNivel();
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
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
                          locked: false,
                          xp: '+10 XP',
                        ),
                        _ActionButton(
                          imagePath:
                              'assets/images/ui/cute_controller_game.png',
                          label: 'Jugar',
                          onTap: grogu.jugar,
                          color: Colors.purple,
                          locked: !grogu.puedeJugar,
                          xp: '+15 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/sleepy_moon.png',
                          label: 'Dormir',
                          onTap: grogu.dormir,
                          color: Colors.indigo,
                          locked: false,
                          xp: '+8 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/small_bath.png',
                          label: 'Bañar',
                          onTap: grogu.banar,
                          color: Colors.cyan,
                          locked: false,
                          xp: '+12 XP',
                        ),
                        _ActionButton(
                          imagePath: 'assets/images/ui/cute_frog.png',
                          label: 'Fuerza',
                          onTap: grogu.usarFuerza,
                          color: Colors.green,
                          locked: !grogu.puedeFuerza,
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
            ],
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
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                widthFactor: grogu.xpProgress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getEtapaColor(grogu.etapa),
                        _getEtapaColor(grogu.etapa).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getEtapaColor(grogu.etapa).withOpacity(0.5),
                        blurRadius: 6,
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

class _ActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.4 : 1.0,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.2), blurRadius: 8),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
                if (locked)
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
              label,
              style: TextStyle(
                color: locked ? Colors.white38 : color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              xp,
              style: TextStyle(
                color: locked ? Colors.white24 : Colors.amber,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
