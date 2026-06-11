import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_controller.dart';
import '../controllers/profile_controller.dart';

class OnboardingProfilePage extends ConsumerStatefulWidget {
  const OnboardingProfilePage({super.key});

  @override
  ConsumerState<OnboardingProfilePage> createState() =>
      _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends ConsumerState<OnboardingProfilePage> {
  final TextEditingController _ageController = TextEditingController();
  AppFontSize? _suggestedFontSize;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _calculateFontSize() {
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0 || age > 120) {
      setState(() => _suggestedFontSize = null);
      return;
    }
    final suggested = fontSizeFromAge(age);
    setState(() => _suggestedFontSize = suggested);
    ref.read(appFontSizeProvider.notifier).state = suggested;
  }

  Future<void> _continue() async {
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa una edad válida')));
      return;
    }

    final fontSize = fontSizeFromAge(age);
    final themeMode = ref.read(themeModeProvider);
    ref.read(appFontSizeProvider.notifier).state = fontSize;

    await ref
        .read(profileControllerProvider.notifier)
        .saveInitialProfile(age: age, fontSize: fontSize, themeMode: themeMode);

    if (!mounted) return;

    final profileState = ref.read(profileControllerProvider);
    if (profileState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: ${profileState.error}')),
      );
      return;
    }

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final currentFontSize = ref.watch(appFontSizeProvider);
    final profileState = ref.watch(profileControllerProvider);
    final isSaving = profileState.isLoading;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top azul con logo ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenido a PastillasPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personalicemos tu experiencia antes de comenzar.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Card blanca ────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // ── Edad ─────────────────────────
                      Text(
                        '¿Cuántos años tienes?',
                        style: tt.titleMedium?.copyWith(color: cs.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Usaremos tu edad para sugerir un tamaño de letra cómodo.',
                        style: tt.bodyMedium,
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _ageController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          hintText: 'Ej: 65',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        onChanged: (_) => _calculateFontSize(),
                      ),

                      const SizedBox(height: 20),

                      // ── Sugerencia font ───────────────
                      if (_suggestedFontSize != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.text_fields,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tamaño sugerido: ${_suggestedFontSize!.label}',
                                  style: tt.titleMedium?.copyWith(
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Tamaño actual ─────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2E8B57,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF2E8B57),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tamaño activo: ${currentFontSize.label}',
                              style: tt.bodyMedium?.copyWith(
                                color: const Color(0xFF1B5E20),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Botón ─────────────────────────
                      ElevatedButton(
                        onPressed: isSaving ? null : _continue,
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continuar'),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
