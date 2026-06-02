import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/medicine_scan_controller.dart';

class ScanMedicinePage extends ConsumerStatefulWidget {
  const ScanMedicinePage({super.key});

  @override
  ConsumerState<ScanMedicinePage> createState() => _ScanMedicinePageState();
}

class _ScanMedicinePageState extends ConsumerState<ScanMedicinePage> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  Future<void> _pickImageFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });

    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });

    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });

    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  Future<void> _analyzeImage() async {
    final image = _selectedImage;

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una imagen')),
      );
      return;
    }

    await ref
        .read(medicineScanControllerProvider.notifier)
        .analyzeMedicineImage(image);
  }

  void _registerMedicationFromAI(String result) {
    final data = _parseAIResult(result);

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo convertir el resultado de IA. Revisa que sea JSON válido.',
          ),
        ),
      );
      return;
    }

    context.push('/medications/new', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(medicineScanControllerProvider);
    final isLoading = scanState.isLoading;

    ref.listen(medicineScanControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo analizar la imagen: $error')),
          );
        },
      );
    });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Escanear receta',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Toma una foto de tu receta o medicamento para extraer sus datos automáticamente.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona una imagen',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes tomar una foto con la cámara o elegir una imagen desde tu galería.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Elegir de galería'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.file(
                      _selectedImage!,
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Imagen seleccionada',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _analyzeImage,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            isLoading ? 'Analizando...' : 'Analizar con IA',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _clearImage,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Quitar imagen'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          scanState.when(
            data: (result) {
              if (result == null || result.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Resultado de IA',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Revisa los datos extraídos. Luego podrás completar o corregir la información antes de guardar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        result,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _registerMedicationFromAI(result),
                        icon: const Icon(Icons.medication),
                        label: const Text(
                          'Registrar medicamento con estos datos',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Analizando imagen...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
            error: (error, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error al analizar: $error',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic>? _parseAIResult(String result) {
  try {
    final cleanText = _cleanJsonText(result);
    final decoded = jsonDecode(cleanText);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  } catch (_) {
    return null;
  }
}

String _cleanJsonText(String text) {
  var cleaned = text.trim();

  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.replaceFirst('```json', '').trim();
  }

  if (cleaned.startsWith('```')) {
    cleaned = cleaned.replaceFirst('```', '').trim();
  }

  if (cleaned.endsWith('```')) {
    cleaned = cleaned.substring(0, cleaned.length - 3).trim();
  }

  final start = cleaned.indexOf('{');
  final end = cleaned.lastIndexOf('}');

  if (start != -1 && end != -1 && end > start) {
    cleaned = cleaned.substring(start, end + 1);
  }

  return cleaned;
}
