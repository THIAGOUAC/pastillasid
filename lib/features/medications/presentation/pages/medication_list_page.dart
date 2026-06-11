import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/medication_entity.dart';
import '../controllers/medication_controller.dart';

class MedicationListPage extends ConsumerWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
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
                    Icons.medication,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mis Medicamentos', style: tt.titleLarge),
                      Text(
                        'Tratamientos, dosis y horarios',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'AGREGAR MEDICAMENTO',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          _ActionCard(
            icon: Icons.edit_note_rounded,
            iconBg: cs.primary,
            title: 'Registro manual',
            subtitle: 'Ingresa nombre, dosis y horarios a mano',
            onTap: () => context.push('/medications/new'),
          ),

          _ActionCard(
            icon: Icons.document_scanner_rounded,
            iconBg: const Color(0xFF2E8B57),
            title: 'Escanear con IA',
            subtitle: 'Foto de receta o medicamento → registro automático',
            onTap: () => context.push('/scan'),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MIS TRATAMIENTOS',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (medications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${medications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (medications.isEmpty)
            _EmptyState()
          else
            ...medications.map((m) => _MedicationCard(medication: m)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: tt.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin medicamentos aún',
                style: tt.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega tu primer medicamento usando las opciones de arriba.',
                style: tt.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final MedicationEntity medication;
  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final bool lowStock = medication.hasLowStock;
    final Color avatarBg = lowStock
        ? cs.error.withValues(alpha: 0.12)
        : cs.primary.withValues(alpha: 0.10);
    final Color avatarIcon = lowStock ? cs.error : cs.primary;

    final doseText =
        '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}';

    return Card(
      child: InkWell(
        onTap: () => context.push('/medications/${medication.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _medicationIcon(medication.type),
                  color: avatarIcon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medication.name, style: tt.titleMedium),
                    const SizedBox(height: 4),
                    Text(doseText, style: tt.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            medication.times.join('  •  '),
                            style: tt.bodyMedium?.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: avatarBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lowStock
                            ? '⚠ Stock bajo: ${_formatNumber(medication.currentStock)}'
                            : 'Stock: ${_formatNumber(medication.currentStock)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: avatarIcon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: () => ref
                    .read(medicationListProvider.notifier)
                    .deleteMedication(medication.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
