import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/intro_screen.dart';
import 'screens/daily_message_screen.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Check if intro has been seen before
  final prefs = await SharedPreferences.getInstance();
  final yaVioIntro = prefs.getBool('yaVioIntro') ?? false;
  final yaVioFraseHoy = _yaVioFraseHoy(prefs);

  runApp(MayTheFabiApp(
    yaVioIntro: yaVioIntro,
    yaVioFraseHoy: yaVioFraseHoy,
  ));
}

bool _yaVioFraseHoy(SharedPreferences prefs) {
  final ultimaFecha = prefs.getString('ultimaFechaFrase');
  if (ultimaFecha == null) return false;
  final hoy = DateTime.now();
  final fechaGuardada = DateTime.parse(ultimaFecha);
  return fechaGuardada.year == hoy.year &&
      fechaGuardada.month == hoy.month &&
      fechaGuardada.day == hoy.day;
}

class MayTheFabiApp extends StatelessWidget {
  final bool yaVioIntro;
  final bool yaVioFraseHoy;

  const MayTheFabiApp({
    super.key,
    required this.yaVioIntro,
    required this.yaVioFraseHoy,
  });

  @override
  Widget build(BuildContext context) {
    // Decide which screen to show first
    Widget homeScreen;
    if (!yaVioIntro) {
      homeScreen = const IntroScreen(); // Primera vez → intro regalo
    } else if (!yaVioFraseHoy) {
      homeScreen = const DailyMessageScreen(); // Nuevo día → frase
    } else {
      homeScreen = const GameScreen(); // Ya vio todo hoy → directo al juego
    }

    return MaterialApp(
      title: 'May the Fabi be with you',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'serif',
      ),
      home: homeScreen,
    );
  }
}
