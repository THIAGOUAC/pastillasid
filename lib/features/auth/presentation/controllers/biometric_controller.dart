import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/biometric_data_source.dart';

final biometricDataSourceProvider = Provider<BiometricDataSource>((ref) {
  return BiometricDataSource();
});

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(biometricDataSourceProvider).isAvailable();
});

final biometricTypesProvider = FutureProvider<List<BiometricType>>((ref) async {
  return ref.read(biometricDataSourceProvider).getAvailableBiometrics();
});

// Estado del proceso de autenticación biométrica
final biometricAuthProvider =
    StateNotifierProvider<BiometricAuthNotifier, AsyncValue<bool?>>((ref) {
  return BiometricAuthNotifier(ref.read(biometricDataSourceProvider));
});

class BiometricAuthNotifier extends StateNotifier<AsyncValue<bool?>> {
  final BiometricDataSource _dataSource;

  BiometricAuthNotifier(this._dataSource) : super(const AsyncValue.data(null));

  Future<bool> authenticate() async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.authenticate();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}