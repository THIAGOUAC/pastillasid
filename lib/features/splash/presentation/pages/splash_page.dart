import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), _checkSession);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }

    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (profileDoc.exists) {
      final data = profileDoc.data();
      if (data != null) {
        final fontSize = _fontSizeFromString(data['fontSize'] as String?);
        final themeMode = _themeModeFromString(data['themeMode'] as String?);
        ref.read(appFontSizeProvider.notifier).state = fontSize;
        ref.read(themeModeProvider.notifier).state = themeMode;
      }
      // Va al login para que ofrezca biometría
      context.go('/login');
    } else {
      context.go('/onboarding-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Nombre ────────────────────────────────
                const Text(
                  'PastillasPE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Tu asistente de medicamentos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Loader ────────────────────────────────
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

AppFontSize _fontSizeFromString(String? value) {
  return AppFontSize.values.firstWhere(
    (fontSize) => fontSize.name == value,
    orElse: () => AppFontSize.normal,
  );
}

ThemeMode _themeModeFromString(String? value) {
  return ThemeMode.values.firstWhere(
    (themeMode) => themeMode.name == value,
    orElse: () => ThemeMode.system,
  );
}
