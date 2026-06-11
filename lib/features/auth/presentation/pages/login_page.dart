import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../controllers/auth_controller.dart';
import '../controllers/biometric_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final biometricAvail = ref.watch(biometricAvailableProvider);
    final biometricTypes = ref.watch(biometricTypesProvider);
    final biometricState = ref.watch(biometricAuthProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasExistingSession = FirebaseAuth.instance.currentUser != null;
    final isLoading = authState.isLoading || biometricState.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/onboarding-profile');
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo iniciar sesión: $error'),
              backgroundColor: cs.error,
            ),
          );
        },
      );
    });

    ref.listen(biometricAuthProvider, (_, next) {
      next.whenOrNull(
        data: (success) {
          if (success == true) context.go('/home');
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error biométrico: $error'),
              backgroundColor: cs.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'PastillasPE',
                style: tt.headlineLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'Tu asistente de medicamentos.\nOrganiza tratamientos, dosis y horarios.',
                style: tt.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Features ──────────────────────────────
              _FeatureRow(
                icon: Icons.notifications_active_outlined,
                color: cs.primary,
                text: 'Recordatorios diarios de tus medicamentos',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.document_scanner_outlined,
                color: const Color(0xFF2E8B57),
                text: 'Escanea recetas con inteligencia artificial',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFFC9952A),
                text: 'Control de stock y alertas de reabastecimiento',
              ),

              const Spacer(flex: 1),

              // ── Botón biométrico (solo si hay sesión activa) ──
              biometricAvail.when(
                data: (available) {
                  if (!available || !hasExistingSession) {
                    return const SizedBox.shrink();
                  }
                  final types = biometricTypes.value ?? [];
                  final isFace = types.contains(BiometricType.face);
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => ref
                                    .read(biometricAuthProvider.notifier)
                                    .authenticate(),
                          icon: biometricState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isFace ? Icons.face : Icons.fingerprint,
                                  size: 22,
                                ),
                          label: Text(
                            biometricState.isLoading
                                ? 'Verificando...'
                                : isFace
                                ? 'Entrar con Face ID'
                                : 'Entrar con huella',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Separador
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: cs.primary.withValues(alpha: 0.20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('o', style: tt.bodyMedium),
                          ),
                          Expanded(
                            child: Divider(
                              color: cs.primary.withValues(alpha: 0.20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ── Botón Google ──────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: authState.isLoading ? null : cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (authState.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.login, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        authState.isLoading
                            ? 'Ingresando...'
                            : 'Continuar con Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Al continuar aceptas el uso de tus datos\npara gestionar tus medicamentos.',
                style: tt.bodyMedium?.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
