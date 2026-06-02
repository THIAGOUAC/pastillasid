import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String actionTaken = 'action_taken';
  static const String actionSnooze = 'action_snooze';

  static const AndroidNotificationChannel _medicationChannel =
      AndroidNotificationChannel(
        'medication_reminders',
        'Recordatorios de medicamentos',
        description: 'Notificaciones para recordar tomas de medicamentos',
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

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_medicationChannel);

    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Pastillas ID',
      'Notificación de prueba funcionando',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de medicamentos',
          channelDescription:
              'Notificaciones para recordar tomas de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showLowStockNotification({
    required String medicationName,
    required double currentStock,
  }) async {
    await _notifications.show(
      medicationName.hashCode.abs() % 2147483647,
      'Stock bajo',
      '$medicationName está por acabarse. Stock actual: ${_formatNumber(currentStock)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de medicamentos',
          channelDescription:
              'Notificaciones para recordar tomas de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleDailyMedicationReminders({
    required String medicationId,
    required String medicationName,
    required String doseText,
    required List<String> times,
  }) async {
    await cancelMedicationReminders(medicationId, times.length);

    for (var index = 0; index < times.length; index++) {
      final time = times[index];
      final scheduledDate = _nextDateTimeForTime(time);
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
    );
  }

  static Future<void> cancelMedicationReminders(
    String medicationId,
    int totalTimes,
  ) async {
    for (var index = 0; index < totalTimes; index++) {
      final notificationId = _notificationIdFromMedication(
        medicationId: medicationId,
        index: index,
      );

      await _notifications.cancel(notificationId);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static AndroidNotificationDetails _medicationNotificationDetails() {
    return const AndroidNotificationDetails(
      'medication_reminders',
      'Recordatorios de medicamentos',
      channelDescription: 'Notificaciones para recordar tomas de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          actionTaken,
          'Ya tomé',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          'Lo tomaré en 10 min',
          showsUserInterface: true,
        ),
      ],
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == actionTaken) {
      // Por ahora abrimos la app. Luego conectamos esto con registrar toma automáticamente.
      return;
    }

    if (actionId == actionSnooze && payload != null) {
      final parts = payload.split('|');

      if (parts.length >= 3) {
        scheduleSnoozeReminder(
          medicationName: parts[1],
          doseText: parts[2],
          minutes: 10,
        );
      }
    }
  }

  static tz.TZDateTime _nextDateTimeForTime(String time) {
    final parts = time.split(':');

    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static int _notificationIdFromMedication({
    required String medicationId,
    required int index,
  }) {
    final base = medicationId.hashCode.abs();
    return (base + index) % 2147483647;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}
