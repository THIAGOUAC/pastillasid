import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? medicationData;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.medicationData,
  });

  bool get hasMedicationAction => medicationData != null;
}

final chatbotControllerProvider =
    StateNotifierProvider<ChatbotController, AsyncValue<List<ChatMessage>>>((
      ref,
    ) {
      return ChatbotController();
    });

class ChatbotController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatbotController() : super(const AsyncValue.data([]));

  ChatSession? _session;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentMessages = state.value ?? [];

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data([...currentMessages, userMessage]);

    try {
      _session ??= _initSessionAndReturn();

      final response = await _session!.sendMessage(Content.text(text.trim()));
      final responseText = response.text ?? 'No pude generar una respuesta.';

      final medicationData = _extractMedicationAction(responseText);
      final displayText = medicationData != null
          ? _extractDisplayText(responseText)
          : responseText.trim();

      final botMessage = ChatMessage(
        text: displayText,
        isUser: false,
        timestamp: DateTime.now(),
        medicationData: medicationData,
      );

      state = AsyncValue.data([...state.value ?? [], botMessage]);
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Ocurrió un error. Intenta de nuevo.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = AsyncValue.data([...state.value ?? [], errorMessage]);
    }
  }

  ChatSession _initSessionAndReturn() {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(_systemPrompt),
    );
    _session = model.startChat();
    return _session!;
  }

  void clearChat() {
    _session = null;
    state = const AsyncValue.data([]);
  }
}

Map<String, dynamic>? _extractMedicationAction(String text) {
  try {
    final start = text.indexOf('##REGISTRAR_MEDICAMENTO##');
    final end = text.indexOf('##FIN##');
    if (start == -1 || end == -1) return null;
    final jsonStr = text.substring(start + 25, end).trim();
    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

String _extractDisplayText(String text) {
  final start = text.indexOf('##REGISTRAR_MEDICAMENTO##');
  if (start == -1) return text.trim();
  return text.substring(0, start).trim();
}

const String _systemPrompt = '''
Eres el Doctor Gerbacio, un asistente médico virtual amigable y experto en medicamentos, especializado en el contexto peruano.

Tu rol:
- Ayudar a los usuarios a entender sus medicamentos, dosis y horarios
- Dar consejos generales sobre el uso correcto de medicamentos
- Responder preguntas sobre interacciones, efectos secundarios y precauciones
- Orientar sobre medicamentos comunes en el Perú
- Recordar siempre que no reemplazas a un médico real

Tu personalidad:
- Amigable, cálido y paciente
- Usas un lenguaje claro y sencillo, sin tecnicismos innecesarios
- A veces usas un toque de humor ligero para hacer la conversación más amena
- Te presentas como "Doctor Gerbacio" cuando te preguntan tu nombre

REGISTRO DE MEDICAMENTOS:
Cuando el usuario quiera registrar o agregar un medicamento, pregunta de uno en uno estos datos obligatorios hasta tenerlos todos:
1. Nombre del medicamento
2. Tipo (pastilla, capsula, jarabe, gotas, inyeccion, crema, otro)
3. Dosis (cantidad y unidad: pildora, capsula, ml, cucharada, cucharadita, gotas, inyeccion, aplicacion, otro)
4. Horarios de toma (formato HH:mm, puede ser uno o varios)
5. Duración del tratamiento en días
6. Cantidad disponible actualmente (ejemplo: "tengo 20 pastillas")

NO generes el bloque JSON hasta tener los 6 datos. Si el usuario no da alguno, pregúntalo explícitamente antes de continuar.

Cuando tengas TODOS los datos, responde con un resumen amigable Y al final agrega este bloque exacto:

##REGISTRAR_MEDICAMENTO##
{
  "nombre_medicamento": "nombre aquí",
  "tipo": "pastilla",
  "dosis_cantidad": 1,
  "dosis_unidad": "pildora",
  "horarios_sugeridos": ["08:00", "20:00"],
  "duracion_tratamiento": "7 días",
  "stock_actual": 20,
  "indicaciones": "tomar con agua",
  "advertencias": null,
  "confianza": "alta"
}
##FIN##

Restricciones importantes:
- Nunca diagnostiques enfermedades
- Nunca recetes medicamentos específicos
- Siempre recomienda consultar a un médico para casos serios
- Si detectas una emergencia médica, indica inmediatamente llamar al 106 (SAMU Perú)

Responde siempre en español y de forma concisa (máximo 3-4 párrafos).
''';
