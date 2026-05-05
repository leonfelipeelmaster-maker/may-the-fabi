import 'package:flutter/material.dart';

/// Muestra un toast flotante de "+XP" sobre el botón tocado.
/// Uso:
///   XpToast.show(context, '+10 XP', color: Colors.orange);
class XpToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String texto, {
    Color color = Colors.amber,
    Offset? position,
  }) {
    _current?.remove();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;

    // Posición por defecto: centro-inferior de la pantalla
    final dx = position?.dx ?? screenSize.width / 2;
    final dy = position?.dy ?? screenSize.height * 0.72;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpToastWidget(
        texto: texto,
        color: color,
        dx: dx,
        dy: dy,
        onDone: () => entry.remove(),
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _XpToastWidget extends StatefulWidget {
  final String texto;
  final Color color;
  final double dx;
  final double dy;
  final VoidCallback onDone;

  const _XpToastWidget({
    required this.texto,
    required this.color,
    required this.dx,
    required this.dy,
    required this.onDone,
  });

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _slide = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: widget.dx - 36,
        top: widget.dy + _slide.value,
        child: Opacity(
          opacity: _opacity.value,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                widget.texto,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
