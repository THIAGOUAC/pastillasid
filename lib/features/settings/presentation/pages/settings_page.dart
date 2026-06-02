import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _savePreferences(WidgetRef ref) async {
    final fontSize = ref.read(appFontSizeProvider);
    final themeMode = ref.read(themeModeProvider);

    await ref
        .read(profileControllerProvider.notifier)
        .updatePreferences(fontSize: fontSize, themeMode: themeMode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(appFontSizeProvider);
    final profileState = ref.watch(profileControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Perfil y configuración',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Consulta tu perfil y ajusta la apariencia de la aplicación.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (profileState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          _ProfileCard(user: user),
          const SizedBox(height: 20),
          Text(
            'Tema de la aplicación',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _ThemeOptionTile(
            title: 'Usar tema del sistema',
            icon: Icons.phone_android,
            selected: themeMode == ThemeMode.system,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.system;
              await _savePreferences(ref);
            },
          ),
          _ThemeOptionTile(
            title: 'Modo claro',
            icon: Icons.light_mode,
            selected: themeMode == ThemeMode.light,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.light;
              await _savePreferences(ref);
            },
          ),
          _ThemeOptionTile(
            title: 'Modo oscuro',
            icon: Icons.dark_mode,
            selected: themeMode == ThemeMode.dark,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              await _savePreferences(ref);
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Tamaño de letra',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...AppFontSize.values.map((size) {
            return _FontSizeOptionTile(
              title: size.label,
              selected: fontSize == size,
              onTap: () async {
                ref.read(appFontSizeProvider.notifier).state = size;
                await _savePreferences(ref);
              },
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await NotificationService.showTestNotification();
            },
            icon: const Icon(Icons.notifications),
            label: const Text('Probar notificación'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();

              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User? user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No hay usuario autenticado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final name = data?['name'] as String? ?? user!.displayName ?? 'Usuario';
        final email = data?['email'] as String? ?? user!.email ?? 'Sin correo';
        final age = data?['age'];
        final photoUrl = data?['photoUrl'] as String? ?? user!.photoURL;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 8),
                _ProfileInfoRow(
                  icon: Icons.cake,
                  label: 'Edad',
                  value: age == null ? 'No registrada' : '$age años',
                ),
                _ProfileInfoRow(
                  icon: Icons.verified_user,
                  label: 'Cuenta',
                  value: 'Google',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: selected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}

class _FontSizeOptionTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FontSizeOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.text_fields,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: selected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}
