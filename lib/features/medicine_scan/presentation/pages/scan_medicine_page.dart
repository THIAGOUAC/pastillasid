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
    setState(() => _selectedImage = File(image.path));
    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _selectedImage = File(image.path));
    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  void _clearImage() {
    setState(() => _selectedImage = null);
    ref.read(medicineScanControllerProvider.notifier).clearResult();
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una imagen')),
      );
      return;
    }
    await ref
        .read(medicineScanControllerProvider.notifier)
        .analyzeMedicineImage(_selectedImage!);
  }

  void _registerMedicationFromAI(String result) {
    final data = _parseAIResult(result);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo procesar el resultado. Intenta de nuevo.'),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen(medicineScanControllerProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al analizar: $error'),
              backgroundColor: cs.error,
            ),
          );
        },
      );
    });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B57),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Escanear receta', style: tt.titleLarge),
                    Text(
                      'Extrae datos con inteligencia artificial',
                      style: tt.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Selector de imagen ───────────────────────────
          if (_selectedImage == null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 48,
                        color: Color(0xFF2E8B57),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una imagen',
                      style: tt.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Receta médica, caja, frasco o etiqueta del medicamento.',
                      style: tt.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar foto'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Elegir de galería'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // ── Preview imagen ───────────────────────────
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      Image.file(
                        _selectedImage!,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: isLoading ? null : _clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _analyzeImage,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            isLoading
                                ? 'Analizando imagen...'
                                : 'Analizar con IA',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Cambiar imagen'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Resultado IA ─────────────────────────────────
          scanState.when(
            data: (result) {
              if (result == null || result.isEmpty) {
                return const SizedBox.shrink();
              }

              final parsed = _parseAIResult(result);
              final confianza = parsed?['confianza']?.toString() ?? 'baja';
              final nombre = parsed?['nombre_medicamento']?.toString();
              final tipo = parsed?['tipo']?.toString();
              final dosis = parsed?['dosis_cantidad']?.toString();
              final unidad = parsed?['dosis_unidad']?.toString();
              final frecuencia = parsed?['frecuencia']?.toString();
              final duracion = parsed?['duracion_tratamiento']?.toString();
              final indicaciones = parsed?['indicaciones']?.toString();
              final advertencias = parsed?['advertencias']?.toString();
              final horarios = parsed?['horarios_sugeridos'];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título resultado
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF2E8B57),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Datos extraídos por IA', style: tt.titleMedium),
                          const Spacer(),
                          _ConfianzaBadge(confianza: confianza),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Revisa los datos antes de guardar. La IA puede cometer errores.',
                        style: tt.bodyMedium,
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Datos parseados
                      if (nombre != null)
                        _DataRow(
                          icon: Icons.medication,
                          label: 'Medicamento',
                          value: nombre,
                        ),
                      if (tipo != null)
                        _DataRow(
                          icon: Icons.category_outlined,
                          label: 'Tipo',
                          value: tipo,
                        ),
                      if (dosis != null || unidad != null)
                        _DataRow(
                          icon: Icons.format_list_numbered,
                          label: 'Dosis',
                          value: [dosis, unidad].whereType<String>().join(' '),
                        ),
                      if (frecuencia != null)
                        _DataRow(
                          icon: Icons.repeat,
                          label: 'Frecuencia',
                          value: frecuencia,
                        ),
                      if (duracion != null)
                        _DataRow(
                          icon: Icons.date_range,
                          label: 'Duración',
                          value: duracion,
                        ),
                      if (horarios is List && horarios.isNotEmpty)
                        _DataRow(
                          icon: Icons.schedule,
                          label: 'Horarios',
                          value: horarios.join(', '),
                        ),
                      if (indicaciones != null)
                        _DataRow(
                          icon: Icons.notes,
                          label: 'Indicaciones',
                          value: indicaciones,
                        ),
                      if (advertencias != null)
                        _DataRow(
                          icon: Icons.warning_amber_outlined,
                          label: 'Advertencias',
                          value: advertencias,
                          isWarning: true,
                        ),

                      if (parsed == null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'No se pudo parsear el resultado. Intenta de nuevo con otra imagen.',
                            style: tt.bodyMedium?.copyWith(color: cs.error),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: parsed != null
                            ? () => _registerMedicationFromAI(result)
                            : null,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Registrar medicamento'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Escanear otra imagen'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text('Analizando imagen con IA...', style: tt.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Esto puede tomar unos segundos.',
                      style: tt.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No se pudo analizar la imagen. Intenta con otra foto.',
                        style: tt.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = isWarning ? cs.error : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}

class _ConfianzaBadge extends StatelessWidget {
  final String confianza;
  const _ConfianzaBadge({required this.confianza});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (confianza.toLowerCase()) {
      case 'alta':
        bg = const Color(0xFF2E8B57).withValues(alpha: 0.12);
        fg = const Color(0xFF1B5E20);
        break;
      case 'media':
        bg = const Color(0xFFC9952A).withValues(alpha: 0.15);
        fg = const Color(0xFF7A5A00);
        break;
      default:
        bg = Theme.of(context).colorScheme.error.withValues(alpha: 0.10);
        fg = Theme.of(context).colorScheme.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Confianza: $confianza',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────

Map<String, dynamic>? _parseAIResult(String result) {
  try {
    final cleanText = _cleanJsonText(result);
    final decoded = jsonDecode(cleanText);
    if (decoded is Map<String, dynamic>) return decoded;
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
