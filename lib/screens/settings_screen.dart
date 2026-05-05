import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/grogu_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _codigoGenerado;
  final TextEditingController _codigoController = TextEditingController();
  bool _restaurando = false;
  String? _mensaje;
  bool _mensajeExito = true;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();

    final datos = {
      'hambre': prefs.getDouble('hambre') ?? 80.0,
      'felicidad': prefs.getDouble('felicidad') ?? 80.0,
      'energia': prefs.getDouble('energia') ?? 80.0,
      'salud': prefs.getDouble('salud') ?? 80.0,
      'nivel': prefs.getInt('nivel') ?? 1,
      'xp': prefs.getInt('xp') ?? 0,
      'xpParaSiguienteNivel': prefs.getInt('xpParaSiguienteNivel') ?? 100,
    };

    // Encode to base64 to make it a shareable code
    final jsonStr = jsonEncode(datos);
    final codigo = base64Encode(utf8.encode(jsonStr));
    // Split in groups of 6 for readability
    final codigoFormateado = _formatearCodigo(codigo);

    setState(() {
      _codigoGenerado = codigoFormateado;
      _mensaje = '✅ ¡Código generado! Guárdalo en un lugar seguro.';
      _mensajeExito = true;
    });
  }

  Future<void> _restaurarProgreso() async {
    final codigo = _codigoController.text.trim().replaceAll(' ', '').replaceAll('-', '');

    if (codigo.isEmpty) {
      setState(() {
        _mensaje = '⚠️ Ingresa un código primero';
        _mensajeExito = false;
      });
      return;
    }

    try {
      final jsonStr = utf8.decode(base64Decode(codigo));
      final datos = jsonDecode(jsonStr) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hambre', (datos['hambre'] as num).toDouble());
      await prefs.setDouble('felicidad', (datos['felicidad'] as num).toDouble());
      await prefs.setDouble('energia', (datos['energia'] as num).toDouble());
      await prefs.setDouble('salud', (datos['salud'] as num).toDouble());
      await prefs.setInt('nivel', datos['nivel'] as int);
      await prefs.setInt('xp', datos['xp'] as int);
      await prefs.setInt('xpParaSiguienteNivel', datos['xpParaSiguienteNivel'] as int);

      setState(() {
        _mensaje = '✅ ¡Progreso restaurado! Reinicia la app para ver los cambios.';
        _mensajeExito = true;
        _restaurando = false;
        _codigoController.clear();
      });
    } catch (e) {
      setState(() {
        _mensaje = '❌ Código inválido. Verifica que lo copiaste correctamente.';
        _mensajeExito = false;
      });
    }
  }

  String _formatearCodigo(String codigo) {
    // Format in groups of 6 separated by spaces for readability
    final buffer = StringBuffer();
    for (int i = 0; i < codigo.length; i++) {
      if (i > 0 && i % 6 == 0) buffer.write(' ');
      buffer.write(codigo[i]);
    }
    return buffer.toString();
  }

  void _copiarCodigo() {
    if (_codigoGenerado != null) {
      Clipboard.setData(ClipboardData(text: _codigoGenerado!));
      setState(() {
        _mensaje = '📋 ¡Código copiado al portapapeles!';
        _mensajeExito = true;
      });
    }
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
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '⚙️ Ajustes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grogu image
                      Center(
                        child: Image.asset(
                          'assets/images/grogu/Feliz_1.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          '✨ May the Fabi be with you ✨',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save progress section
                      _sectionTitle('📤 Guardar Progreso'),
                      const SizedBox(height: 8),
                      const Text(
                        'Genera un código con tu progreso actual. Guárdalo para restaurarlo después de reinstalar la app.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(
                        '📤 Generar código',
                        Colors.blue,
                        _guardarProgreso,
                      ),

                      // Show generated code
                      if (_codigoGenerado != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu código de progreso:',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _codigoGenerado!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _copiarCodigo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy,
                                          color: Colors.blue, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Copiar código',
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Restore progress section
                      _sectionTitle('📥 Restaurar Progreso'),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa tu código de progreso para recuperar tu avance.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      if (!_restaurando)
                        _primaryButton(
                          '📥 Restaurar progreso',
                          Colors.green,
                          () => setState(() => _restaurando = true),
                        ),

                      if (_restaurando) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _codigoController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Pega tu código aquí...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _primaryButton(
                                '✅ Restaurar',
                                Colors.green,
                                _restaurarProgreso,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _primaryButton(
                                '❌ Cancelar',
                                Colors.red,
                                () => setState(() {
                                  _restaurando = false;
                                  _codigoController.clear();
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Message
                      if (_mensaje != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _mensajeExito
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _mensajeExito
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.red.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _mensaje!,
                            style: TextStyle(
                              color: _mensajeExito
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Historial
                      _sectionTitle('💀 Historial de Grogu'),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Leer del Provider si está disponible, si no de prefs
                          int muertes = 0;
                          try {
                            muertes = context.watch<GroguState>().contadorMuertes;
                          } catch (_) {}
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: muertes == 0
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: muertes == 0
                                    ? Colors.greenAccent.withOpacity(0.3)
                                    : Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  muertes == 0 ? '🌟' : '💀',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        muertes == 0
                                            ? '¡Grogu está vivo!'
                                            : 'Grogu ha muerto $muertes ${muertes == 1 ? 'vez' : 'veces'}',
                                        style: TextStyle(
                                          color: muertes == 0
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        muertes == 0
                                            ? 'Sigue cuidándolo cada día 💚'
                                            : 'Recuerda cuidarlo todos los días',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // App info
                      _sectionTitle('ℹ️ Acerca de'),
                      const SizedBox(height: 8),
                      _infoRow('Versión', '1.0.0'),
                      _infoRow('Creado con', '💚 para Fabiola'),
                      _infoRow('Fecha', 'May the 4th, 2026'),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _primaryButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
