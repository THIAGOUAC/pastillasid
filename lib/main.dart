import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/notifications/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Captura notificación que abrió la app desde cero
  final launchDetails = await NotificationService.getLaunchDetails();

  await NotificationService.initialize();

  runApp(ProviderScope(child: PastillasApp(launchPayload: launchDetails)));
}
