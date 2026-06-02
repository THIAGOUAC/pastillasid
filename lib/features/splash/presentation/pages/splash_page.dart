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

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
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

      context.go('/home');
    } else {
      context.go('/onboarding-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication_liquid,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Pastillas ID',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
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
