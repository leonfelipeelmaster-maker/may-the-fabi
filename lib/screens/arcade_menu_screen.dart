import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/grogu_state.dart';
import 'frog_game_screen.dart';
import 'tetris_game_screen.dart';

class ArcadeMenuScreen extends StatelessWidget {
  final GroguState grogu;

  const ArcadeMenuScreen({super.key, required this.grogu});

  static const int kFrogUnlockLevel = 3;
  static const int kTetrisUnlockLevel = 6;

  @override
  Widget build(BuildContext context) {
    final frogUnlocked = grogu.nivel >= kFrogUnlockLevel;
    final tetrisUnlocked = grogu.nivel >= kTetrisUnlockLevel;

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
            children: [
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTitle(grogu),
                      const SizedBox(height: 36),
                      _buildGameCard(
                        context,
                        emoji: '🐸',
                        title: 'Atrapa la Rana',
                        description: 'Reflejos rápidos en el espacio.\nAtrapa ranas para ganar XP.',
                        unlockLevel: kFrogUnlockLevel,
                        isUnlocked: frogUnlocked,
                        accentColor: Colors.greenAccent,
                        onPlay: () => _playFrogGame(context, grogu),
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        context,
                        emoji: '🧱',
                        title: 'Tetris Galáctico',
                        description: 'Ordena los bloques del espacio.\nCada línea da XP a Grogu.',
                        unlockLevel: kTetrisUnlockLevel,
                        isUnlocked: tetrisUnlocked,
                        accentColor: Colors.cyanAccent,
                        onPlay: () => _playTetris(context, grogu),
                      ),
                      const SizedBox(height: 36),
                      _buildUnlockHint(grogu),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white60, size: 18),
            ),
          ),
          const Expanded(
            child: Text(
              '🕹️ Arcade',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                shadows: [Shadow(color: Colors.orange, blurRadius: 8)],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildTitle(GroguState grogu) {
    return Column(
      children: [
        const Text('✨', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text(
          'Sala de Juegos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Nivel ${grogu.nivel}  •  ${grogu.xp}/${grogu.xpParaSiguienteNivel} XP',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
    required int unlockLevel,
    required bool isUnlocked,
    required Color accentColor,
    required VoidCallback onPlay,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? accentColor.withOpacity(0.5) : Colors.white12,
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? [accentColor.withOpacity(0.08), const Color(0xFF0d1b4b)]
              : [const Color(0xFF0a0a2e), const Color(0xFF0d1b4b)],
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: accentColor.withOpacity(0.12), blurRadius: 16)]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? accentColor.withOpacity(0.12)
                    : Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: isUnlocked ? accentColor.withOpacity(0.4) : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? emoji : '🔒',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUnlocked
                        ? description
                        : '🔓 Se desbloquea en nivel $unlockLevel',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked
                          ? accentColor.withOpacity(0.8)
                          : Colors.white24,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón
            if (isUnlocked)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPlay();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '▶ Jugar',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Nv. $unlockLevel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockHint(GroguState grogu) {
    String text;
    Color color;
    if (grogu.nivel >= kTetrisUnlockLevel) {
      text = '🏆 ¡Todos los juegos desbloqueados!';
      color = Colors.amber;
    } else if (grogu.nivel >= kFrogUnlockLevel) {
      final needed = kTetrisUnlockLevel - grogu.nivel;
      text = '🧱 Tetris se desbloquea en $needed nivel${needed == 1 ? '' : 'es'} más';
      color = Colors.cyanAccent;
    } else {
      final needed = kFrogUnlockLevel - grogu.nivel;
      text = '🐸 Frog Game en $needed nivel${needed == 1 ? '' : 'es'} más';
      color = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30),
        color: color.withOpacity(0.06),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _playFrogGame(BuildContext context, GroguState grogu) {
    final gameLevel = ((grogu.nivel - 3) ~/ 3) + 1;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FrogGameScreen(
          nivelJuego: gameLevel,
          onGameOver: (xpGanado) => grogu.ganarXPExterno(xpGanado),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _playTetris(BuildContext context, GroguState grogu) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TetrisGameScreen(
          groguLevel: grogu.nivel,
          onGameOver: (xpGanado) => grogu.ganarXPExterno(xpGanado),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
