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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeMedications = medications.where((m) => m.isActive).toList();
    final totalTakesToday = activeMedications.fold<int>(
      0,
      (total, m) => total + m.times.length,
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calendario', style: tt.titleLarge),
                        Text('Seguimiento de tus tomas', style: tt.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Resumen hoy ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TodayBanner(
                totalTakesToday: totalTakesToday,
                totalTakenToday: totalTakenToday,
              ),
            ),

            const SizedBox(height: 20),

            // ── Vista semanal ────────────────────────────
            _SectionLabel(label: 'ESTA SEMANA', color: cs.primary),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WeekStrip(
                weekDays: weekDays,
                medications: activeMedications,
              ),
            ),

            const SizedBox(height: 20),

            // ── Horarios de hoy ──────────────────────────
            _SectionLabel(label: 'HORARIOS DE HOY', color: cs.primary),
            const SizedBox(height: 8),

            if (activeMedications.isEmpty)
              _EmptyHint(
                icon: Icons.medication_outlined,
                text: 'No tienes medicamentos activos.',
              )
            else
              ...activeMedications.map(
                (m) => _MedicationScheduleCard(medication: m),
              ),

            const SizedBox(height: 20),

            // ── Tomas realizadas ─────────────────────────
            _SectionLabel(label: 'TOMAS REALIZADAS HOY', color: cs.primary),
            const SizedBox(height: 8),

            if (intakeRecords.isEmpty)
              _EmptyHint(
                icon: Icons.check_circle_outline,
                text: 'Aún no marcaste ninguna toma hoy.',
              )
            else
              ...intakeRecords.map(
                (record) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2E8B57,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2E8B57),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.medicationName,
                                  style: tt.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(record.doseText, style: tt.bodyMedium),
                                Text(
                                  'Tomado a las ${_formatTime(record.takenAt)}',
                                  style: tt.bodyMedium?.copyWith(
                                    color: const Color(0xFF2E8B57),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ── Resumen mensual ──────────────────────────
            _SectionLabel(label: 'PRÓXIMOS MESES', color: cs.primary),
            const SizedBox(height: 8),

            if (activeMedications.isEmpty)
              _EmptyHint(
                icon: Icons.calendar_today_outlined,
                text: 'Sin tratamientos activos para mostrar.',
              )
            else
              ...monthSummaries.map(
                (summary) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: cs.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(summary.monthLabel, style: tt.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${summary.activeTreatments} tratamiento(s) • '
                                  '${summary.totalTakes} toma(s)',
                                  style: tt.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Banner resumen hoy ─────────────────────────────────────
class _TodayBanner extends StatelessWidget {
  final int totalTakesToday;
  final int totalTakenToday;

  const _TodayBanner({
    required this.totalTakesToday,
    required this.totalTakenToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = (totalTakesToday - totalTakenToday).clamp(
      0,
      totalTakesToday,
    );
    final progress = totalTakesToday == 0
        ? 0.0
        : (totalTakenToday / totalTakesToday).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalTakenToday de $totalTakesToday tomas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$remaining pendiente(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Strip semanal ──────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  final List<_WeekDayInfo> weekDays;
  final List<MedicationEntity> medications;

  const _WeekStrip({required this.weekDays, required this.medications});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((day) {
        final isToday = _isSameDate(day.date, DateTime.now());
        final isPast = day.date.isBefore(DateTime.now()) && !isToday;
        final takes = _totalTakesForDate(medications, day.date);

        return Expanded(
          child: Column(
            children: [
              Text(
                day.label.substring(0, 2),
                style: tt.labelSmall?.copyWith(
                  color: isToday
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.50),
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday
                      ? cs.primary
                      : isPast
                      ? cs.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday
                      ? null
                      : Border.all(color: cs.primary.withValues(alpha: 0.20)),
                ),
                child: Center(
                  child: Text(
                    '${day.date.day}',
                    style: TextStyle(
                      color: isToday ? Colors.white : cs.onSurface,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                takes > 0 ? '$takes' : '-',
                style: tt.labelSmall?.copyWith(
                  color: takes > 0
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Card horario medicamento ───────────────────────────────
class _MedicationScheduleCard extends StatelessWidget {
  final MedicationEntity medication;
  const _MedicationScheduleCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medication, color: cs.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(medication.name, style: tt.titleMedium)),
                  Text(
                    '${medication.times.length} toma(s)',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: medication.times.map((time) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}',
                style: tt.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary.withValues(alpha: 0.40), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelos ────────────────────────────────────────────────
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

// ── Helpers ────────────────────────────────────────────────
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
  return List.generate(7, (i) {
    final date = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day + i,
    );
    return _WeekDayInfo(label: labels[i], date: date);
  });
}

int _totalTakesForDate(List<MedicationEntity> medications, DateTime date) {
  var total = 0;
  for (final m in medications) {
    if (_isMedicationActiveOnDate(m, date)) total += m.times.length;
  }
  return total;
}

List<_MonthSummary> _buildMonthSummaries(List<MedicationEntity> medications) {
  final now = DateTime.now();
  return List.generate(4, (index) {
    final monthDate = DateTime(now.year, now.month + index);
    final startOfMonth = DateTime(monthDate.year, monthDate.month);
    final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final activeInMonth = medications
        .where((m) => _isMedicationActiveBetween(m, startOfMonth, endOfMonth))
        .toList();

    var totalTakes = 0;
    for (final m in activeInMonth) {
      final start = m.startDate.isAfter(startOfMonth)
          ? m.startDate
          : startOfMonth;
      final end = _medicationEndDate(m);
      final effectiveEnd = end != null && end.isBefore(endOfMonth)
          ? end
          : endOfMonth;
      final days = effectiveEnd.difference(start).inDays + 1;
      if (days > 0) totalTakes += days * m.times.length;
    }

    return _MonthSummary(
      monthLabel: _formatMonth(monthDate),
      activeTreatments: activeInMonth.length,
      totalTakes: totalTakes,
    );
  });
}

bool _isMedicationActiveOnDate(MedicationEntity m, DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
  final end = _medicationEndDate(m);
  if (dateOnly.isBefore(start)) return false;
  if (end != null && dateOnly.isAfter(end)) return false;
  return m.isActive;
}

bool _isMedicationActiveBetween(
  MedicationEntity m,
  DateTime start,
  DateTime end,
) {
  final treatmentStart = DateTime(
    m.startDate.year,
    m.startDate.month,
    m.startDate.day,
  );
  final treatmentEnd = _medicationEndDate(m);
  if (treatmentEnd != null && treatmentEnd.isBefore(start)) return false;
  if (treatmentStart.isAfter(end)) return false;
  return m.isActive;
}

DateTime? _medicationEndDate(MedicationEntity m) {
  if (m.endDate != null) {
    return DateTime(m.endDate!.year, m.endDate!.month, m.endDate!.day);
  }
  if (m.treatmentDays != null) {
    return DateTime(
      m.startDate.year,
      m.startDate.month,
      m.startDate.day + m.treatmentDays! - 1,
    );
  }
  return null;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _doseUnitLabel(dynamic unit) {
  switch (unit.toString().split('.').last) {
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
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

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
