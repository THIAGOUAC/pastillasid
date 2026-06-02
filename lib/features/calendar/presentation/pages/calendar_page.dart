import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../medications/domain/entities/medication_entity.dart';
import '../../../medications/presentation/controllers/medication_controller.dart';
import '../../../reminders/presentation/controllers/intake_record_controller.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);
    final intakeRecords = ref.watch(intakeRecordControllerProvider);

    final activeMedications = medications.where((medication) {
      return medication.isActive;
    }).toList();

    final totalTakesToday = activeMedications.fold<int>(
      0,
      (total, medication) => total + medication.times.length,
    );

    final totalTakenToday = intakeRecords.length;
    final weekDays = _buildCurrentWeek();
    final monthSummaries = _buildMonthSummaries(activeMedications);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(intakeRecordControllerProvider.notifier)
              .loadTodayRecords();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Almanaque de tomas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen diario, semanal y mensual de tus medicamentos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _TodaySummaryCard(
              totalTakesToday: totalTakesToday,
              totalTakenToday: totalTakenToday,
            ),
            const SizedBox(height: 16),
            Text(
              'Vista del día',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (activeMedications.isEmpty)
              const _EmptyCard(
                message:
                    'Cuando registres medicamentos activos, aparecerán aquí sus horarios.',
              )
            else
              ...activeMedications.map((medication) {
                return Card(
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.medication,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${medication.times.length} toma(s) hoy',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    children: medication.times.map((time) {
                      return ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text('Hora: $time'),
                        subtitle: Text(
                          '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}',
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            const SizedBox(height: 16),
            Text(
              'Tomas realizadas hoy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (intakeRecords.isEmpty)
              const _EmptyCard(
                message: 'Aún no marcaste ninguna toma como realizada hoy.',
              )
            else
              ...intakeRecords.map((record) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      record.medicationName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${record.doseText}\nTomado a las ${_formatTime(record.takenAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            const SizedBox(height: 16),
            Text(
              'Vista semanal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: weekDays.map((day) {
                    final totalForDay = _totalTakesForDate(
                      activeMedications,
                      day.date,
                    );
                    final isToday = _isSameDate(day.date, DateTime.now());

                    return _WeekDayRow(
                      label: day.label,
                      dateText: _formatShortDate(day.date),
                      totalTakes: totalForDay,
                      isToday: isToday,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vista mensual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (activeMedications.isEmpty)
              const _EmptyCard(
                message:
                    'Cuando tengas tratamientos activos, verás aquí su duración mensual.',
              )
            else
              ...monthSummaries.map((summary) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(summary.monthLabel),
                    subtitle: Text(
                      '${summary.activeTreatments} tratamiento(s) activo(s)\n${summary.totalTakes} toma(s) programada(s) en el mes',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final int totalTakesToday;
  final int totalTakenToday;

  const _TodaySummaryCard({
    required this.totalTakesToday,
    required this.totalTakenToday,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalTakesToday - totalTakenToday;
    final safeRemaining = remaining < 0 ? 0 : remaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.today,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '$totalTakesToday toma(s) programada(s) hoy',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$totalTakenToday tomada(s) • $safeRemaining pendiente(s)',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  final String label;
  final String dateText;
  final int totalTakes;
  final bool isToday;

  const _WeekDayRow({
    required this.label,
    required this.dateText,
    required this.totalTakes,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isToday
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
        child: Icon(
          isToday ? Icons.today : Icons.calendar_today,
          color: isToday
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
      ),
      title: Text(
        isToday ? '$label (hoy)' : label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(dateText),
      trailing: Text(
        '$totalTakes toma(s)',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _WeekDayInfo {
  final String label;
  final DateTime date;

  const _WeekDayInfo({required this.label, required this.date});
}

class _MonthSummary {
  final String monthLabel;
  final int activeTreatments;
  final int totalTakes;

  const _MonthSummary({
    required this.monthLabel,
    required this.activeTreatments,
    required this.totalTakes,
  });
}

List<_WeekDayInfo> _buildCurrentWeek() {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  const labels = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  return List.generate(7, (index) {
    final date = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day + index,
    );

    return _WeekDayInfo(label: labels[index], date: date);
  });
}

int _totalTakesForDate(List<MedicationEntity> medications, DateTime date) {
  var total = 0;

  for (final medication in medications) {
    if (_isMedicationActiveOnDate(medication, date)) {
      total += medication.times.length;
    }
  }

  return total;
}

List<_MonthSummary> _buildMonthSummaries(List<MedicationEntity> medications) {
  final now = DateTime.now();

  return List.generate(4, (index) {
    final monthDate = DateTime(now.year, now.month + index);
    final startOfMonth = DateTime(monthDate.year, monthDate.month);
    final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final activeInMonth = medications.where((medication) {
      return _isMedicationActiveBetween(medication, startOfMonth, endOfMonth);
    }).toList();

    var totalTakes = 0;

    for (final medication in activeInMonth) {
      final start = medication.startDate.isAfter(startOfMonth)
          ? medication.startDate
          : startOfMonth;
      final end = _medicationEndDate(medication);
      final effectiveEnd = end != null && end.isBefore(endOfMonth)
          ? end
          : endOfMonth;

      final days = effectiveEnd.difference(start).inDays + 1;

      if (days > 0) {
        totalTakes += days * medication.times.length;
      }
    }

    return _MonthSummary(
      monthLabel: _formatMonth(monthDate),
      activeTreatments: activeInMonth.length,
      totalTakes: totalTakes,
    );
  });
}

bool _isMedicationActiveOnDate(MedicationEntity medication, DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final start = DateTime(
    medication.startDate.year,
    medication.startDate.month,
    medication.startDate.day,
  );

  final end = _medicationEndDate(medication);

  if (dateOnly.isBefore(start)) return false;
  if (end != null && dateOnly.isAfter(end)) return false;

  return medication.isActive;
}

bool _isMedicationActiveBetween(
  MedicationEntity medication,
  DateTime start,
  DateTime end,
) {
  final treatmentStart = DateTime(
    medication.startDate.year,
    medication.startDate.month,
    medication.startDate.day,
  );

  final treatmentEnd = _medicationEndDate(medication);

  if (treatmentEnd != null && treatmentEnd.isBefore(start)) return false;
  if (treatmentStart.isAfter(end)) return false;

  return medication.isActive;
}

DateTime? _medicationEndDate(MedicationEntity medication) {
  if (medication.endDate != null) {
    return DateTime(
      medication.endDate!.year,
      medication.endDate!.month,
      medication.endDate!.day,
    );
  }

  if (medication.treatmentDays != null) {
    return DateTime(
      medication.startDate.year,
      medication.startDate.month,
      medication.startDate.day + medication.treatmentDays! - 1,
    );
  }

  return null;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _doseUnitLabel(dynamic unit) {
  final text = unit.toString().split('.').last;

  switch (text) {
    case 'pill':
      return 'píldora(s)';
    case 'capsule':
      return 'cápsula(s)';
    case 'ml':
      return 'ml';
    case 'tablespoon':
      return 'cucharada(s)';
    case 'teaspoon':
      return 'cucharadita(s)';
    case 'drops':
      return 'gota(s)';
    case 'injection':
      return 'inyección(es)';
    case 'application':
      return 'aplicación(es)';
    default:
      return 'unidad(es)';
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month';
}

String _formatMonth(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${months[date.month - 1]} ${date.year}';
}
