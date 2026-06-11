import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../router/app_router.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String actionTaken = 'action_taken';
  static const String actionSnooze = 'action_snooze';

  static const String _channelId = 'medication_reminders';
  static const String _channelName = 'Recordatorios de medicamentos';
  static const String _channelDescription =
      'Notificaciones para recordar tomas de medicamentos';

  static const AndroidNotificationChannel _medicationChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_medicationChannel);
    await requestPermissions();
  }

  // Obtiene el payload si la app fue abierta por notificación
  static Future<String?> getLaunchDetails() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  // Procesa el payload independientemente de cómo llegó
  static void handlePayload(String payload) {
    if (payload.isEmpty) return;
    final parts = payload.split('|');
    final medName = parts.length > 1 ? parts[1] : 'Medicamento';
    final doseText = parts.length > 2 ? parts[2] : '';

    showMedicationDialog(
      medicationName: medName,
      doseText: doseText,
      payload: payload,
    );
  }

  static Future<void> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'PastillasPE',
      'Notificacion funcionando correctamente',
      NotificationDetails(android: _basicNotificationDetails()),
    );
  }

  static Future<void> scheduleTestIn15Seconds() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 15));
    await _notifications.zonedSchedule(
      998,
      'Prueba programada',
      'Si ves esto, el scheduling funciona correctamente',
      scheduledDate,
      NotificationDetails(android: _medicationNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showLowStockNotification({
    required String medicationName,
    required double currentStock,
  }) async {
    await _notifications.show(
      medicationName.hashCode.abs() % 2147483647,
      'Stock bajo - PastillasPE',
      '$medicationName esta por acabarse. Stock: ${_formatNumber(currentStock)}',
      NotificationDetails(android: _basicNotificationDetails()),
    );
  }

  static Future<void> scheduleDailyMedicationReminders({
    required String medicationId,
    required String medicationName,
    required String doseText,
    required List<String> times,
  }) async {
    await cancelMedicationReminders(medicationId, 20);

    for (var index = 0; index < times.length; index++) {
      final scheduledDate = _nextDateTimeForTime(times[index]);
      final notificationId = _notificationIdFromMedication(
        medicationId: medicationId,
        index: index,
      );
      await _notifications.zonedSchedule(
        notificationId,
        'Hora de tomar tu medicamento',
        '$medicationName - $doseText',
        scheduledDate,
        NotificationDetails(android: _medicationNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '$medicationId|$medicationName|$doseText',
      );
    }
  }

  static Future<void> scheduleSnoozeReminder({
    required String medicationName,
    required String doseText,
    int minutes = 10,
  }) async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));
    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      'Recordatorio pospuesto',
      '$medicationName - $doseText',
      scheduledDate,
      NotificationDetails(android: _medicationNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'snooze|$medicationName|$doseText',
    );
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String doseText,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      'Hora de tomar tu medicamento',
      '$medicationName - $doseText',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: _medicationNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$id|$medicationName|$doseText',
    );
  }

  static Future<void> cancelMedicationReminders(
    String medicationId,
    int totalTimes,
  ) async {
    for (var index = 0; index < totalTimes; index++) {
      await _notifications.cancel(
        _notificationIdFromMedication(medicationId: medicationId, index: index),
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ── Diálogo in-app ─────────────────────────────────────
  static void showMedicationDialog({
    required String medicationName,
    required String doseText,
    required String payload,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MedicationReminderDialog(
        medicationName: medicationName,
        doseText: doseText,
        payload: payload,
      ),
    );
  }

  static AndroidNotificationDetails _basicNotificationDetails() {
    return const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );
  }

  static AndroidNotificationDetails _medicationNotificationDetails() {
    return const AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      actions: [
        AndroidNotificationAction(
          actionTaken,
          'Ya tome',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          'Lo tomare en 10 min',
          showsUserInterface: true,
        ),
      ],
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    final medName = parts.length > 1 ? parts[1] : 'Medicamento';
    final doseText = parts.length > 2 ? parts[2] : '';

    if (actionId == actionTaken) return;

    if (actionId == actionSnooze) {
      scheduleSnoozeReminder(
        medicationName: medName,
        doseText: doseText,
        minutes: 10,
      );
      return;
    }

    // Tap sin acción → mostrar diálogo
    showMedicationDialog(
      medicationName: medName,
      doseText: doseText,
      payload: payload,
    );
  }

  static tz.TZDateTime _nextDateTimeForTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static int _notificationIdFromMedication({
    required String medicationId,
    required int index,
  }) {
    return (medicationId.hashCode.abs() + index) % 2147483647;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

// ── Diálogo emergente in-app ───────────────────────────────
class _MedicationReminderDialog extends StatelessWidget {
  final String medicationName;
  final String doseText;
  final String payload;

  const _MedicationReminderDialog({
    required this.medicationName,
    required this.doseText,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication, color: cs.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Hora de tu medicamento',
              style: tt.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              medicationName,
              style: tt.titleMedium?.copyWith(color: cs.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(doseText, style: tt.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Ya lo tome'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  NotificationService.scheduleSnoozeReminder(
                    medicationName: medicationName,
                    doseText: doseText,
                    minutes: 10,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Te recordamos en 10 minutos'),
                    ),
                  );
                },
                icon: const Icon(Icons.snooze),
                label: const Text('Recordarme en 10 min'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
