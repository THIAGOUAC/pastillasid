import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/intake_record_entity.dart';

final intakeRecordControllerProvider =
    StateNotifierProvider<IntakeRecordController, List<IntakeRecordEntity>>(
  (ref) => IntakeRecordController()..loadTodayRecords(),
);

class IntakeRecordController extends StateNotifier<List<IntakeRecordEntity>> {
  IntakeRecordController() : super(const []);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _recordsCollection {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intake_history');
  }

  Future<void> loadTodayRecords() async {
    final collection = _recordsCollection;

    if (collection == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await collection
        .where('takenAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('takenAt', isLessThan: endOfDay.toIso8601String())
        .orderBy('takenAt', descending: true)
        .get();

    state = snapshot.docs.map((doc) {
      return IntakeRecordEntity.fromMap(doc.data());
    }).toList();
  }

  Future<void> addRecord(IntakeRecordEntity record) async {
    final collection = _recordsCollection;

    if (collection == null) return;

    await collection.doc(record.id).set(record.toMap());

    state = [record, ...state];
  }
}