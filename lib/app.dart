import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

import 'core/router/app_router.dart';

class PastillasApp extends ConsumerWidget {
  const PastillasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pastillas ID',
      theme: AppTheme.lightTheme(fontScale: fontScale),
      darkTheme: AppTheme.darkTheme(fontScale: fontScale),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
