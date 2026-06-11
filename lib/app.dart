import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';

class PastillasApp extends ConsumerStatefulWidget {
  final String? launchPayload;
  const PastillasApp({super.key, this.launchPayload});

  @override
  ConsumerState<PastillasApp> createState() => _PastillasAppState();
}

class _PastillasAppState extends ConsumerState<PastillasApp> {
  @override
  void initState() {
    super.initState();
    // Mostrar diálogo si la app fue abierta por notificación
    if (widget.launchPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          NotificationService.handlePayload(widget.launchPayload!);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PastillasPE',
      theme: AppTheme.lightTheme(fontScale: fontScale),
      darkTheme: AppTheme.darkTheme(fontScale: fontScale),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
