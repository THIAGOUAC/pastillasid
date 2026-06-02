import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_controller.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
      return ProfileController();
    });

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController() : super(const AsyncValue.data(null));

  Future<void> saveInitialProfile({
    required int age,
    required AppFontSize fontSize,
    required ThemeMode themeMode,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'age': age,
        'fontSize': fontSize.name,
        'themeMode': themeMode.name,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePreferences({
    required AppFontSize fontSize,
    required ThemeMode themeMode,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fontSize': fontSize.name,
        'themeMode': themeMode.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
