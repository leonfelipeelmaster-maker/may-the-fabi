import 'package:shared_preferences/shared_preferences.dart';

class DailyMessage {
  static const List<String> _frases = [
    "¡Hoy vas a ser increíble, Fabiola! 🌟",
    "La Fuerza está contigo hoy ✨",
    "Grogu cree en ti 💚",
    "¡Eres más fuerte que un Jedi!",
    "¡Despierta, el universo te necesita hoy!",
    "Grogu soñó contigo... y fue bonito 🌙",
    "Hoy es un gran día para ser tú, Fabiola",
    "¡El lado luminoso de la Fuerza te acompaña!",
    "May the Fabi be with you... siempre 🌟",
    "Yoda diría: especial eres, Fabiola",
    "En una galaxia muy lejana... nació alguien increíble 🚀",
    "No necesitas un sable de luz, tú ya brillas sola ✨",
    "Grogu eligió ser tu compañero Jedi 💚",
    "Hasta Mando te protegería, eso dice todo 🛡️",
    "El Mandaloriano dice: este es el camino... al corazón de Fabiola",
    "Eres la Fuerza más poderosa de esta galaxia 🌌",
    "Grogu te manda un abrazo hoy 🤗",
    "¡Tu día será tan bonito como tú!",
    "Sonríe, Grogu está aquí contigo 💚",
    "Hoy respira bonito y confía en ti 🌸",
    "Grogu dice: mereces todo lo bueno del universo",
    "¡Tú puedes con todo, Fabiola! Grogu lo sabe 💫",
    "Cada día contigo es una aventura galáctica 🚀",
    "Grogu intentó cocinar la sopa... mejor pide delivery 🍵",
    "¿Sabías que Grogu también tiene Lunes difíciles? Pero los supera 💪",
    "Grogu usó la Fuerza para mandarte buena vibra hoy 🔮",
    "Si Grogu puede sobrevivir al Imperio, tú puedes con tu día 😄",
    "Grogu intentó meditar... se quedó dormido. Tú hazlo mejor 😴",
    "La galaxia es tuya hoy, Fabiola. ¡A conquistarla! 🌌",
    "Descansa bien, mañana habrá nuevas aventuras 🌙",
    "Grogu cuida tus sueños esta noche ✨",
    "Hoy hiciste tu mejor esfuerzo, eso es suficiente 💚",
    "El universo está orgulloso de ti hoy, Fabiola 🌌",
    "¡Tú eres la aventura más bonita de esta galaxia! 💫",
    "Grogu dice que hoy va a ser tu mejor día 🌟",
    "Respira. Sonríe. La Fuerza está contigo 💚",
    "Fabiola, hoy el universo conspira a tu favor 🌌✨",
  ];

  static const String fraseCumpleanos =
      "¡Feliz Cumpleaños, Fabiola! 🎂🌟\nMay the 4th be with you...\n¡Hoy toda la galaxia celebra contigo! 🎉";

  static const String fraseBienvenida =
      "Eres la persona favorita de Grogu en toda la galaxia 💚";

  static Future<String> getFraseDelDia() async {
    final prefs = await SharedPreferences.getInstance();
    final yaVioFraseBienvenida =
        prefs.getBool('yaVioFraseBienvenida') ?? false;

    // Primera vez — frase especial de bienvenida
    if (!yaVioFraseBienvenida) {
      await prefs.setBool('yaVioFraseBienvenida', true);
      return fraseBienvenida;
    }

    // Frase especial el 4 de mayo
    if (esCumpleanos()) return fraseCumpleanos;

    // Frases diarias rotativas
    final now = DateTime.now();
    final diaDelAnio = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _frases[diaDelAnio % _frases.length];
  }

  static bool esCumpleanos() {
    final now = DateTime.now();
    return now.month == 5 && now.day == 4;
  }
}
