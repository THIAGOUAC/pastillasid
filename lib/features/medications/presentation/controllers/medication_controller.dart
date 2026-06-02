import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../reminders/domain/entities/intake_record_entity.dart';
import '../../domain/entities/medication_entity.dart';

final medicationListProvider =
    StateNotifierProvider<MedicationController, List<MedicationEntity>>((ref) {
      return MedicationController()..loadMedications();
    });

class MedicationController extends StateNotifier<List<MedicationEntity>> {
  MedicationController() : super(const []);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _medicationsCollection {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medications');
  }

  Future<void> loadMedications() async {
    final collection = _medicationsCollection;

    if (collection == null) return;

    final snapshot = await collection.orderBy('name').get();

    final medications = snapshot.docs.map((doc) {
      return MedicationEntity.fromMap(doc.data());
    }).toList();

    state = medications;

    for (final medication in medications) {
      if (medication.isActive) {
        await _scheduleMedicationNotifications(medication);
      }
    }
  }

  Future<void> addMedication(MedicationEntity medication) async {
    final collection = _medicationsCollection;

    if (collection == null) return;

    await collection.doc(medication.id).set(medication.toMap());

    await _scheduleMedicationNotifications(medication);

    state = [...state, medication];
  }

  Future<void> updateMedication(MedicationEntity medication) async {
    final collection = _medicationsCollection;

    if (collection == null) return;

    await collection
        .doc(medication.id)
        .set(medication.toMap(), SetOptions(merge: true));

    if (medication.isActive) {
      await _scheduleMedicationNotifications(medication);
    } else {
      await NotificationService.cancelMedicationReminders(
        medication.id,
        medication.times.length,
      );
    }

    state = state.map((item) {
      if (item.id == medication.id) {
        return medication;
      }

      return item;
    }).toList();
  }

  Future<void> deleteMedication(String id) async {
    final collection = _medicationsCollection;

    if (collection == null) return;

    final medication = state.where((item) => item.id == id).firstOrNull;

    if (medication != null) {
      await NotificationService.cancelMedicationReminders(
        medication.id,
        medication.times.length,
      );
    }

    await collection.doc(id).delete();

    state = state.where((item) => item.id != id).toList();
  }

  Future<void> toggleMedicationStatus(String id) async {
    final medication = state.where((item) => item.id == id).firstOrNull;

    if (medication == null) return;

    final updatedMedication = medication.copyWith(
      isActive: !medication.isActive,
    );

    await updateMedication(updatedMedication);
  }

  Future<void> markDoseAsTaken(String id) async {
    final medication = state.where((item) => item.id == id).firstOrNull;

    if (medication == null) return;

    final newStock = medication.currentStock - medication.stockPerDose;

    final updatedMedication = medication.copyWith(
      currentStock: newStock < 0 ? 0 : newStock,
    );

    await updateMedication(updatedMedication);

    await _saveIntakeRecord(updatedMedication);

    if (updatedMedication.hasLowStock) {
      await NotificationService.showLowStockNotification(
        medicationName: updatedMedication.name,
        currentStock: updatedMedication.currentStock,
      );
    }
  }

  Future<void> _scheduleMedicationNotifications(
    MedicationEntity medication,
  ) async {
    await NotificationService.scheduleDailyMedicationReminders(
      medicationId: medication.id,
      medicationName: medication.name,
      doseText:
          '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}',
      times: medication.times,
    );
  }

  Future<void> _saveIntakeRecord(MedicationEntity medication) async {
    final user = _auth.currentUser;

    if (user == null) return;

    final recordId = DateTime.now().millisecondsSinceEpoch.toString();

    final record = IntakeRecordEntity(
      id: recordId,
      medicationId: medication.id,
      medicationName: medication.name,
      doseText:
          '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}',
      takenAt: DateTime.now(),
      status: IntakeStatus.taken,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intake_history')
        .doc(record.id)
        .set(record.toMap());
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
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
