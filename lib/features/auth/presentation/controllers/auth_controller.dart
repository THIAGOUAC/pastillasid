import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController();
    });

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController() : super(AsyncValue.data(FirebaseAuth.instance.currentUser));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '1088707971501-9ub20asd1n8vbi8vrr7ua702ecml7hl6.apps.googleusercontent.com',
      );

      await GoogleSignIn.instance.signOut();

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      state = AsyncValue.data(userCredential.user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
