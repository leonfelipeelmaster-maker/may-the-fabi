import 'package:flutter/material.dart';

class StatsBar extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final String iconPath;

  const StatsBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.iconPath,
  });

  @override
  State<StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<StatsBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnim;

  bool get _enPeligro => widget.value < 20;
  bool get _critico => widget.value < 10;

  Color get _barColor {
    if (_critico) return Colors.red;
    if (_enPeligro) return Colors.orange;
    return widget.color;
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    if (_enPeligro) _blinkController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatsBar old) {
    super.didUpdateWidget(old);
    if (_enPeligro && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!_enPeligro && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          // Ícono con parpadeo si está en peligro
          AnimatedBuilder(
            animation: _blinkAnim,
            builder: (_, child) => Opacity(
              opacity: _enPeligro ? _blinkAnim.value : 1.0,
              child: child,
            ),
            child: Stack(
              children: [
                Image.asset(widget.iconPath, width: 28, height: 28),
                if (_enPeligro)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _critico ? Colors.red : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: _enPeligro ? _barColor : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4)
                        ],
                      ),
                    ),
                    if (_enPeligro) ...[
                      const SizedBox(width: 4),
                      Text(
                        _critico ? '¡CRÍTICO!' : '¡Bajo!',
                        style: TextStyle(
                          color: _barColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      widthFactor: widget.value / 100,
                      child: AnimatedBuilder(
                        animation: _blinkAnim,
                        builder: (_, child) => Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: _enPeligro
                                ? _barColor.withOpacity(_blinkAnim.value)
                                : widget.color,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _barColor.withOpacity(
                                    _enPeligro ? _blinkAnim.value * 0.8 : 0.5),
                                blurRadius: _enPeligro ? 10 : 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _blinkAnim,
            builder: (_, __) => Text(
              '${widget.value.toInt()}%',
              style: TextStyle(
                color: _enPeligro ? _barColor : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
