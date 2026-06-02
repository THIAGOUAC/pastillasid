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
      setState(() {
        _suggestedFontSize = null;
      });
      return;
    }

    final suggested = fontSizeFromAge(age);

    setState(() {
      _suggestedFontSize = suggested;
    });

    ref.read(appFontSizeProvider.notifier).state = suggested;
  }

  Future<void> _continue() async {
    final age = int.tryParse(_ageController.text.trim());

    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero ingresa una edad válida')),
      );
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
        SnackBar(
          content: Text('No se pudo guardar el perfil: ${profileState.error}'),
        ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil inicial')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Personalicemos tu experiencia',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Usaremos tu edad para sugerir un tamaño de letra cómodo. Luego podrás cambiarlo en configuración.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _ageController,
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Edad',
                      hintText: 'Ejemplo: 65',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    onChanged: (_) => _calculateFontSize(),
                  ),
                  const SizedBox(height: 20),
                  if (_suggestedFontSize != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Tamaño sugerido: ${_suggestedFontSize!.label}',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Tamaño actual: ${currentFontSize.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isSaving ? null : _continue,
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
