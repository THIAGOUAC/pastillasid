import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/medication_entity.dart';
import '../controllers/medication_controller.dart';

class MedicationDetailPage extends ConsumerWidget {
  final String medicationId;
  const MedicationDetailPage({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);
    final medication = medications
        .where((m) => m.id == medicationId)
        .firstOrNull;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (medication == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicamento')),
        body: const Center(child: Text('No se encontró el medicamento')),
      );
    }

    final doseText =
        '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}';
    final bool lowStock = medication.hasLowStock;

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/medications/edit/${medication.id}'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Hero card ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _medicationIcon(medication.type),
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: tt.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doseText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: medication.isActive
                                ? Colors.white.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            medication.isActive ? 'Activo' : 'Desactivado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Alerta stock bajo ──────────────────────
            if (lowStock) ...[
              Container(
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
                        'Stock bajo — considera reabastecerte pronto.',
                        style: tt.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Acciones rápidas ───────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Ya tomé',
                    color: const Color(0xFF2E8B57),
                    enabled: medication.currentStock > 0,
                    onTap: () async {
                      await ref
                          .read(medicationListProvider.notifier)
                          .markDoseAsTaken(medication.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Toma registrada y stock actualizado',
                            ),
                            backgroundColor: Color(0xFF2E8B57),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.snooze,
                    label: 'En 10 min',
                    color: const Color(0xFFC9952A),
                    enabled: medication.isActive,
                    onTap: () async {
                      await NotificationService.scheduleSnoozeReminder(
                        medicationName: medication.name,
                        doseText: doseText,
                        minutes: 10,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recordatorio en 10 minutos'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Info: Dosis ────────────────────────────
            _InfoSection(
              icon: Icons.medication,
              title: 'Dosis',
              color: cs.primary,
              rows: [
                _InfoItem(
                  label: 'Tipo',
                  value: _medicationTypeLabel(medication.type),
                ),
                _InfoItem(label: 'Cantidad', value: doseText),
              ],
            ),

            const SizedBox(height: 12),

            // ── Info: Horarios ─────────────────────────
            _InfoSection(
              icon: Icons.schedule,
              title: 'Horarios de toma',
              color: cs.primary,
              rows: medication.times
                  .map((t) => _InfoItem(label: 'Toma', value: t))
                  .toList(),
            ),

            const SizedBox(height: 12),

            // ── Info: Tratamiento ──────────────────────
            _InfoSection(
              icon: Icons.date_range,
              title: 'Tratamiento',
              color: cs.primary,
              rows: [
                _InfoItem(
                  label: 'Inicio',
                  value: _formatDate(medication.startDate),
                ),
                _InfoItem(
                  label: 'Duración',
                  value: medication.treatmentDays == null
                      ? 'No especificada'
                      : '${medication.treatmentDays} día(s)',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Info: Stock ────────────────────────────
            _InfoSection(
              icon: Icons.inventory_2_outlined,
              title: 'Stock',
              color: lowStock ? cs.error : cs.primary,
              rows: [
                _InfoItem(
                  label: 'Disponible',
                  value: _formatNumber(medication.currentStock),
                ),
                _InfoItem(
                  label: 'Por toma',
                  value: _formatNumber(medication.stockPerDose),
                ),
                _InfoItem(
                  label: 'Alerta cuando queden',
                  value: _formatNumber(medication.minimumStockAlert),
                ),
              ],
            ),

            if (medication.instructions != null) ...[
              const SizedBox(height: 12),
              _InfoSection(
                icon: Icons.notes,
                title: 'Indicaciones',
                color: cs.primary,
                rows: [
                  _InfoItem(label: 'Nota', value: medication.instructions!),
                ],
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ── Controles ──────────────────────────────
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/medications/edit/${medication.id}'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar medicamento'),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () => ref
                  .read(medicationListProvider.notifier)
                  .toggleMedicationStatus(medication.id),
              icon: Icon(
                medication.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              label: Text(
                medication.isActive
                    ? 'Desactivar tratamiento'
                    : 'Activar tratamiento',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: medication.isActive
                    ? const Color(0xFFC9952A)
                    : const Color(0xFF2E8B57),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(medicationListProvider.notifier)
                    .deleteMedication(medication.id);
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.delete_outline, color: cs.error),
              label: Text(
                'Eliminar medicamento',
                style: TextStyle(color: cs.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Info section ───────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<_InfoItem> rows;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: tt.titleMedium?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.label,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(child: Text(row.value, style: tt.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

// ── Action button ──────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.10)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.30)
                : Colors.grey.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────
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

String _medicationTypeLabel(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return 'Pastilla';
    case MedicationType.capsule:
      return 'Cápsula';
    case MedicationType.syrup:
      return 'Jarabe';
    case MedicationType.drops:
      return 'Gotas';
    case MedicationType.injection:
      return 'Inyección';
    case MedicationType.cream:
      return 'Crema';
    case MedicationType.other:
      return 'Otro';
  }
}

String _doseUnitLabel(DoseUnit unit) {
  switch (unit) {
    case DoseUnit.pill:
      return 'píldora(s)';
    case DoseUnit.capsule:
      return 'cápsula(s)';
    case DoseUnit.ml:
      return 'ml';
    case DoseUnit.tablespoon:
      return 'cucharada(s)';
    case DoseUnit.teaspoon:
      return 'cucharadita(s)';
    case DoseUnit.drops:
      return 'gota(s)';
    case DoseUnit.injection:
      return 'inyección(es)';
    case DoseUnit.application:
      return 'aplicación(es)';
    case DoseUnit.other:
      return 'unidad(es)';
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
