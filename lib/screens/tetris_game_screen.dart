import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sound_manager.dart';

// ─── Modelo de pieza Tetris ───────────────────────────────────────────────────
class TetrisPiece {
  final List<List<int>> shape;
  final Color color;
  final String name;

  const TetrisPiece({
    required this.shape,
    required this.color,
    required this.name,
  });

  TetrisPiece rotate() {
    final rows = shape.length;
    final cols = shape[0].length;
    final rotated = List.generate(
      cols,
      (i) => List.generate(rows, (j) => shape[rows - 1 - j][i]),
    );
    return TetrisPiece(shape: rotated, color: color, name: name);
  }
}

// ─── Piezas disponibles ───────────────────────────────────────────────────────
final List<TetrisPiece> kTetrisPieces = [
  // I
  TetrisPiece(
    name: 'I',
    color: const Color(0xFF00FFFF),
    shape: [
      [1, 1, 1, 1]
    ],
  ),
  // O
  TetrisPiece(
    name: 'O',
    color: const Color(0xFFFFFF00),
    shape: [
      [1, 1],
      [1, 1]
    ],
  ),
  // T
  TetrisPiece(
    name: 'T',
    color: const Color(0xFFBB00FF),
    shape: [
      [0, 1, 0],
      [1, 1, 1]
    ],
  ),
  // S
  TetrisPiece(
    name: 'S',
    color: const Color(0xFF00FF88),
    shape: [
      [0, 1, 1],
      [1, 1, 0]
    ],
  ),
  // Z
  TetrisPiece(
    name: 'Z',
    color: const Color(0xFFFF3366),
    shape: [
      [1, 1, 0],
      [0, 1, 1]
    ],
  ),
  // J
  TetrisPiece(
    name: 'J',
    color: const Color(0xFF0066FF),
    shape: [
      [1, 0, 0],
      [1, 1, 1]
    ],
  ),
  // L
  TetrisPiece(
    name: 'L',
    color: const Color(0xFFFF8800),
    shape: [
      [0, 0, 1],
      [1, 1, 1]
    ],
  ),
];

// ─── Constantes del tablero ───────────────────────────────────────────────────
const int kBoardCols = 10;
const int kBoardRows = 20;
const Color kEmptyCell = Colors.transparent;

// ─── TetrisGameScreen ─────────────────────────────────────────────────────────
class TetrisGameScreen extends StatefulWidget {
  /// Nivel actual de Grogu (para calcular XP ganado al terminar)
  final int groguLevel;

  /// Callback que devuelve el XP ganado cuando termina la partida
  final void Function(int xpGained)? onGameOver;

  const TetrisGameScreen({
    super.key,
    required this.groguLevel,
    this.onGameOver,
  });

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen>
    with TickerProviderStateMixin {
  // Tablero: null = vacío, Color = celda ocupada
  late List<List<Color?>> _board;

  // Pieza actual y siguiente
  TetrisPiece? _currentPiece;
  int _currentX = 0;
  int _currentY = 0;
  TetrisPiece? _nextPiece;

  // Estado del juego
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isPaused = false;

  int _score = 0;
  int _lines = 0;
  int _level = 1;

  Timer? _gameTimer;
  final Random _random = Random();
  final SoundManager _sound = SoundManager();
  late final AppLifecycleListener _lifecycleListener;

  // Animaciones
  late AnimationController _flashController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // XP calculado al final
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Pausar automáticamente cuando la app pasa a segundo plano
    _lifecycleListener = AppLifecycleListener(
      onHide: () { if (_isPlaying && !_isPaused) setState(() => _isPaused = true); },
      onInactive: () { if (_isPlaying && !_isPaused) setState(() => _isPaused = true); },
      onResume: () { /* No auto-resume: el usuario decide */ },
    );
    _resetBoard();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _lifecycleListener.dispose();
    _flashController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Lógica del tablero ───────────────────────────────────────────────────

  void _resetBoard() {
    _board = List.generate(
      kBoardRows,
      (_) => List.generate(kBoardCols, (_) => null),
    );
    _score = 0;
    _lines = 0;
    _level = 1;
    _isGameOver = false;
    _isPaused = false;
    _currentPiece = null;
    _nextPiece = _randomPiece();
  }

  TetrisPiece _randomPiece() =>
      kTetrisPieces[_random.nextInt(kTetrisPieces.length)];

  void _spawnPiece() {
    _currentPiece = _nextPiece;
    _nextPiece = _randomPiece();
    _currentX = (kBoardCols - _currentPiece!.shape[0].length) ~/ 2;
    _currentY = 0;

    if (!_isValidPosition(_currentPiece!, _currentX, _currentY)) {
      _triggerGameOver();
    }
  }

  bool _isValidPosition(TetrisPiece piece, int x, int y) {
    for (int row = 0; row < piece.shape.length; row++) {
      for (int col = 0; col < piece.shape[row].length; col++) {
        if (piece.shape[row][col] == 0) continue;
        final boardX = x + col;
        final boardY = y + row;
        if (boardX < 0 || boardX >= kBoardCols) return false;
        if (boardY >= kBoardRows) return false;
        if (boardY >= 0 && _board[boardY][boardX] != null) return false;
      }
    }
    return true;
  }

  void _lockPiece() {
    for (int row = 0; row < _currentPiece!.shape.length; row++) {
      for (int col = 0; col < _currentPiece!.shape[row].length; col++) {
        if (_currentPiece!.shape[row][col] == 0) continue;
        final boardY = _currentY + row;
        final boardX = _currentX + col;
        if (boardY >= 0) {
          _board[boardY][boardX] = _currentPiece!.color;
        }
      }
    }
    _clearLines();
    _spawnPiece();
  }

  void _clearLines() {
    int cleared = 0;
    for (int row = kBoardRows - 1; row >= 0; row--) {
      if (_board[row].every((cell) => cell != null)) {
        _board.removeAt(row);
        _board.insert(0, List.generate(kBoardCols, (_) => null));
        cleared++;
        row++; // revisar la misma fila de nuevo
      }
    }
    if (cleared > 0) {
      _flashController.forward(from: 0);
      HapticFeedback.mediumImpact();
      _sound.celebrar(); // sonido igual que atrapar rana
      const lineScores = [0, 100, 300, 500, 800];
      _score += (lineScores[cleared] * _level);
      _lines += cleared;
      _level = (_lines ~/ 10) + 1;
      _restartTimer();
    }
  }

  void _moveDown() {
    if (_currentPiece == null) return;
    if (_isValidPosition(_currentPiece!, _currentX, _currentY + 1)) {
      setState(() => _currentY++);
    } else {
      setState(() => _lockPiece());
    }
  }

  void _moveLeft() {
    if (_currentPiece == null || _isPaused) return;
    if (_isValidPosition(_currentPiece!, _currentX - 1, _currentY)) {
      setState(() => _currentX--);
      HapticFeedback.selectionClick();
    }
  }

  void _moveRight() {
    if (_currentPiece == null || _isPaused) return;
    if (_isValidPosition(_currentPiece!, _currentX + 1, _currentY)) {
      setState(() => _currentX++);
      HapticFeedback.selectionClick();
    }
  }

  void _rotate() {
    if (_currentPiece == null || _isPaused) return;
    final rotated = _currentPiece!.rotate();
    if (_isValidPosition(rotated, _currentX, _currentY)) {
      setState(() => _currentPiece = rotated);
      HapticFeedback.lightImpact();
    }
  }

  void _hardDrop() {
    if (_currentPiece == null || _isPaused) return;
    int dropY = _currentY;
    while (_isValidPosition(_currentPiece!, _currentX, dropY + 1)) {
      dropY++;
    }
    setState(() {
      _currentY = dropY;
      _score += (dropY - _currentY) * 2;
      _lockPiece();
    });
    HapticFeedback.heavyImpact();
  }

  // ─── Timer y velocidad ────────────────────────────────────────────────────

  Duration get _tickDuration {
    // Empieza más lento (900ms), acelera por nivel (mín 150ms)
    final ms = (900 - (_level - 1) * 60).clamp(150, 900);
    return Duration(milliseconds: ms);
  }

  void _startGame() {
    _resetBoard();
    _spawnPiece();
    setState(() => _isPlaying = true);
    _restartTimer();
  }

  void _restartTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_tickDuration, (_) {
      if (!_isPaused && _isPlaying && !_isGameOver) {
        _moveDown();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _triggerGameOver() {
    _gameTimer?.cancel();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });
    // Calcular XP: score / 10, mínimo 5 XP
    _xpEarned = (_score ~/ 10).clamp(5, 500);
    HapticFeedback.vibrate();
    // Notificar al padre
    widget.onGameOver?.call(_xpEarned);
  }

  // ─── Render del tablero ───────────────────────────────────────────────────

  List<List<Color?>> get _renderBoard {
    final display = List.generate(
      kBoardRows,
      (row) => List<Color?>.from(_board[row]),
    );
    // Superponer pieza actual
    if (_currentPiece != null) {
      for (int row = 0; row < _currentPiece!.shape.length; row++) {
        for (int col = 0; col < _currentPiece!.shape[row].length; col++) {
          if (_currentPiece!.shape[row][col] == 0) continue;
          final boardY = _currentY + row;
          final boardX = _currentX + col;
          if (boardY >= 0 && boardY < kBoardRows && boardX >= 0 && boardX < kBoardCols) {
            display[boardY][boardX] = _currentPiece!.color;
          }
        }
      }
      // Ghost piece (sombra)
      int ghostY = _currentY;
      while (_isValidPosition(_currentPiece!, _currentX, ghostY + 1)) {
        ghostY++;
      }
      if (ghostY != _currentY) {
        for (int row = 0; row < _currentPiece!.shape.length; row++) {
          for (int col = 0; col < _currentPiece!.shape[row].length; col++) {
            if (_currentPiece!.shape[row][col] == 0) continue;
            final boardY = ghostY + row;
            final boardX = _currentX + col;
            if (boardY >= 0 && boardY < kBoardRows && boardX >= 0 && boardX < kBoardCols) {
              if (display[boardY][boardX] == null) {
                display[boardY][boardX] = _currentPiece!.color.withOpacity(0.2);
              }
            }
          }
        }
      }
    }
    return display;
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a2e),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tablero principal
                  Expanded(
                    flex: 3,
                    child: _buildBoard(),
                  ),
                  // Panel lateral
                  _buildSidePanel(),
                ],
              ),
            ),
            // Controles táctiles
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0d1b4b),
            const Color(0xFF0a0a2e),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1a0a3e), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4FC3F7)),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFFBB00FF)],
                ).createShader(bounds),
                child: const Text(
                  '🕹️ TETRIS GALÁCTICO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                'Nivel Grogu: ${widget.groguLevel} ✨',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4FC3F7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isPlaying)
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: const Color(0xFF4FC3F7),
              ),
              onPressed: _togglePause,
              padding: EdgeInsets.zero,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) _moveLeft();
        if (details.velocity.pixelsPerSecond.dx > 200) _moveRight();
      },
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy > 300) _hardDrop();
      },
      onTap: _rotate,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1a0a3e), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              // Fondo estrellado
              _buildStarryBackground(),
              // Tablero
              AspectRatio(
                aspectRatio: kBoardCols / kBoardRows,
                child: _isPlaying || _isGameOver
                    ? _buildCells()
                    : _buildStartScreen(),
              ),
              // Overlay de pausa
              if (_isPaused && _isPlaying) _buildPauseOverlay(),
              // Game Over overlay
              if (_isGameOver) _buildGameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarryBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _StarFieldPainter(),
      ),
    );
  }

  Widget _buildCells() {
    final board = _renderBoard;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kBoardCols,
      ),
      itemCount: kBoardCols * kBoardRows,
      itemBuilder: (context, index) {
        final row = index ~/ kBoardCols;
        final col = index % kBoardCols;
        final color = board[row][col];
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF0d1b4b).withOpacity(0.6),
            borderRadius: BorderRadius.circular(2),
            boxShadow: color != null && color.opacity > 0.3
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 0,
                    )
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: const Text('🐸', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFFBB00FF)],
            ).createShader(bounds),
            child: const Text(
              'TETRIS\nGALÁCTICO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '▶ JUGAR',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '← → Mover  |  Tap Rotar\n↓ Rápido  |  ↑ Hard Drop',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF4FC3F7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: Text(
            '⏸\nPAUSA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              color: Color(0xFF4FC3F7),
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💫', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 28,
                  color: Color(0xFFFF3366),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4FC3F7)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0d1b4b),
                ),
                child: Column(
                  children: [
                    Text(
                      'Puntuación: $_score',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFFFFFF00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Líneas: $_lines',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4FC3F7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$_xpEarned XP para Grogu! ✨',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '🔄 Otra vez',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(_xpEarned),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4FC3F7),
                      side: const BorderSide(color: Color(0xFF4FC3F7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('🚀 Salir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _statCard('SCORE', '$_score', const Color(0xFFFFFF00)),
          const SizedBox(height: 8),
          _statCard('NIVEL', '$_level', const Color(0xFF00FF88)),
          const SizedBox(height: 8),
          _statCard('LÍNEAS', '$_lines', const Color(0xFF4FC3F7)),
          const SizedBox(height: 16),
          // Siguiente pieza
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1a0a3e)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF0d1b4b),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildNextPiece(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // XP potencial
          if (_isPlaying)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF00FF88).withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ XP',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+${(_score ~/ 10).clamp(5, 500)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPiece() {
    if (_nextPiece == null) return const SizedBox(height: 40);
    final shape = _nextPiece!.shape;
    final color = _nextPiece!.color;
    return Column(
      children: shape
          .map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((cell) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: cell == 1 ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: cell == 1
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
                        : null,
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0a0a2e),
        border: Border(top: BorderSide(color: Color(0xFF1a0a3e))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: Icons.arrow_back,
            onPressed: _moveLeft,
            color: const Color(0xFF4FC3F7),
          ),
          _controlButton(
            icon: Icons.rotate_right,
            onPressed: _rotate,
            color: const Color(0xFFBB00FF),
            large: true,
          ),
          _controlButton(
            icon: Icons.vertical_align_bottom,
            onPressed: _hardDrop,
            color: const Color(0xFFFF8800),
          ),
          _controlButton(
            icon: Icons.arrow_forward,
            onPressed: _moveRight,
            color: const Color(0xFF4FC3F7),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool large = false,
    String? tooltip,
  }) {
    final size = large ? 56.0 : 48.0;
    return GestureDetector(
      onTap: _isPlaying && !_isGameOver ? onPressed : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: large ? 28 : 22),
      ),
    );
  }
}

// ─── Painter para el fondo estrellado ─────────────────────────────────────────
class _StarFieldPainter extends CustomPainter {
  static final List<Offset> _stars = List.generate(
    60,
    (i) => Offset(
      (i * 73 % 100) / 100,
      (i * 37 % 100) / 100,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final radius = i % 3 == 0 ? 1.0 : 0.5;
      paint.color = Colors.white.withOpacity(0.2 + (i % 5) * 0.1);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
