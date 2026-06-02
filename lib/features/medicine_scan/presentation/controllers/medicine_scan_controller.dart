import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final medicineScanControllerProvider =
    StateNotifierProvider<MedicineScanController, AsyncValue<String?>>((ref) {
  return MedicineScanController();
});

class MedicineScanController extends StateNotifier<AsyncValue<String?>> {
  MedicineScanController() : super(const AsyncValue.data(null));

  Future<void> analyzeMedicineImage(File imageFile) async {
    state = const AsyncValue.loading();

    try {
      final imageBytes = await imageFile.readAsBytes();

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );

      final response = await model.generateContent([
        Content.multi([
          TextPart(_medicineExtractionPrompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('La IA no devolvió información de la imagen');
      }

      state = AsyncValue.data(text.trim());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearResult() {
    state = const AsyncValue.data(null);
  }
}

const String _medicineExtractionPrompt = '''
Analiza esta imagen de una receta médica, caja, frasco, blíster o etiqueta de medicamento.

Extrae únicamente la información visible en la imagen.

Devuelve la respuesta en español y en formato JSON válido, sin texto adicional fuera del JSON.

Estructura esperada:

{
  "nombre_medicamento": null,
  "tipo": null,
  "dosis_cantidad": null,
  "dosis_unidad": null,
  "frecuencia": null,
  "horarios_sugeridos": [],
  "duracion_tratamiento": null,
  "indicaciones": null,
  "advertencias": null,
  "confianza": "baja"
}

Reglas:
- No inventes datos.
- Si un dato no aparece claramente, usa null.
- En "tipo" usa una de estas opciones si se puede inferir: pastilla, capsula, jarabe, gotas, inyeccion, crema, otro.
- En "dosis_unidad" usa una de estas opciones si se puede inferir: pildora, capsula, ml, cucharada, cucharadita, gotas, inyeccion, aplicacion, otro.
- "horarios_sugeridos" debe ser una lista de horas en formato HH:mm solo si aparecen horarios claros.
- Si solo aparece frecuencia como "cada 8 horas", escribe eso en "frecuencia" y deja "horarios_sugeridos" vacío.
- Esto no reemplaza la indicación médica. Solo extrae texto visible.
''';