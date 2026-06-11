import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../medications/domain/entities/medication_entity.dart';
import '../../../medications/presentation/controllers/medication_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeMedications = medications.where((m) => m.isActive).toList();
    final lowStockMedications = medications
        .where((m) => m.hasLowStock)
        .toList();
    final totalTakesToday = activeMedications.fold<int>(
      0,
      (total, m) => total + m.times.length,
    );
    final nextTake = _findNextTake(activeMedications);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PastillasPE',
                        style: tt.titleLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tu asistente de medicamentos',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Próxima toma (card destacada) ───────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima toma',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.80),
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextTake == null
                              ? 'Sin tomas pendientes hoy'
                              : nextTake.medicationName,
                          style: tt.titleMedium?.copyWith(color: Colors.white),
                        ),
                        if (nextTake != null)
                          Text(
                            'a las ${nextTake.time}',
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats row ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.today,
                    label: 'Tomas hoy',
                    value: '$totalTakesToday',
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.medication,
                    label: 'Activos',
                    value: '${activeMedications.length}',
                    color: const Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning_amber,
                    label: 'Stock bajo',
                    value: '${lowStockMedications.length}',
                    color: lowStockMedications.isNotEmpty
                        ? cs.error
                        : const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Alerta stock bajo ───────────────────────────
          if (lowStockMedications.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: cs.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${lowStockMedications.length} medicamento(s) con stock bajo: '
                        '${lowStockMedications.map((m) => m.name).join(', ')}',
                        style: tt.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Medicamentos activos ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MIS TRATAMIENTOS ACTIVOS',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (activeMedications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 40,
                        color: cs.primary.withValues(alpha: 0.40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin tratamientos activos',
                        style: tt.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ve a Medicamentos para agregar tu primer tratamiento.',
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/medications/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar medicamento'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...activeMedications.map((m) => _MedicationTile(medication: m)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Medication tile ────────────────────────────────────────
class _MedicationTile extends StatelessWidget {
  final MedicationEntity medication;
  const _MedicationTile({required this.medication});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bool lowStock = medication.hasLowStock;
    final Color color = lowStock ? cs.error : cs.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _medicationIcon(medication.type),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: tt.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${medication.times.length} toma(s) al día  •  Stock: ${_formatNumber(medication.currentStock)}',
                    style: tt.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              lowStock
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────
class _NextTake {
  final String medicationName;
  final String time;
  const _NextTake({required this.medicationName, required this.time});
}

_NextTake? _findNextTake(List<MedicationEntity> medications) {
  final now = TimeOfDay.now();
  final nowMinutes = now.hour * 60 + now.minute;
  _NextTake? nextTake;
  int? nextMinutes;

  for (final medication in medications) {
    for (final time in medication.times) {
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      final medicationMinutes = hour * 60 + minute;
      if (medicationMinutes >= nowMinutes) {
        if (nextMinutes == null || medicationMinutes < nextMinutes) {
          nextMinutes = medicationMinutes;
          nextTake = _NextTake(medicationName: medication.name, time: time);
        }
      }
    }
  }
  return nextTake;
}

IconData _medicationIcon(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return Icons.medication;
    case MedicationType.capsule:
      return Icons.medication_liquid;
    case MedicationType.syrup:
      return Icons.local_drink;
    case MedicationType.drops:
      return Icons.water_drop;
    case MedicationType.injection:
      return Icons.vaccines;
    case MedicationType.cream:
      return Icons.spa;
    case MedicationType.other:
      return Icons.medical_services;
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
