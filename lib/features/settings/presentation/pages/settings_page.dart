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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perfil y ajustes', style: tt.titleLarge),
                    Text('Configura tu experiencia', style: tt.bodyMedium),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (profileState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          // ── Tarjeta de perfil ───────────────────────────
          _ProfileCard(user: user),

          const SizedBox(height: 24),

          // ── Tema ────────────────────────────────────────
          _SectionLabel(label: 'TEMA DE LA APLICACIÓN', color: cs.primary),
          const SizedBox(height: 8),

          _OptionTile(
            icon: Icons.phone_android,
            title: 'Sistema',
            subtitle: 'Sigue el tema del dispositivo',
            selected: themeMode == ThemeMode.system,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.system;
              await _savePreferences(ref);
            },
          ),
          _OptionTile(
            icon: Icons.light_mode,
            title: 'Modo claro',
            subtitle: 'Fondo blanco clínico',
            selected: themeMode == ThemeMode.light,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.light;
              await _savePreferences(ref);
            },
          ),
          _OptionTile(
            icon: Icons.dark_mode,
            title: 'Modo oscuro',
            subtitle: 'Fondo azul oscuro',
            selected: themeMode == ThemeMode.dark,
            onTap: () async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              await _savePreferences(ref);
            },
          ),

          const SizedBox(height: 24),

          // ── Tamaño de letra ─────────────────────────────
          _SectionLabel(label: 'TAMAÑO DE LETRA', color: cs.primary),
          const SizedBox(height: 8),

          ...AppFontSize.values.map(
            (size) => _OptionTile(
              icon: Icons.text_fields,
              title: size.label,
              subtitle: '',
              selected: fontSize == size,
              onTap: () async {
                ref.read(appFontSizeProvider.notifier).state = size;
                await _savePreferences(ref);
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Notificaciones ──────────────────────────────
          _SectionLabel(label: 'NOTIFICACIONES', color: cs.primary),
          const SizedBox(height: 8),

          Card(
            child: InkWell(
              onTap: () async => NotificationService.showTestNotification(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Probar notificación', style: tt.titleMedium),
                          Text(
                            'Envía una notificación de prueba',
                            style: tt.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Cerrar sesión ───────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: Icon(Icons.logout, color: cs.error),
            label: Text('Cerrar sesión', style: TextStyle(color: cs.error)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: cs.error)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Sección label ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Option tile unificado ──────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.50),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: tt.bodyMedium),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.30),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final User? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No hay usuario autenticado.', style: tt.bodyMedium),
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
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primary.withValues(alpha: 0.10),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 40, color: cs.primary)
                      : null,
                ),
                const SizedBox(height: 14),

                Text(name, style: tt.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(email, style: tt.bodyMedium, textAlign: TextAlign.center),

                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerTheme.color),
                const SizedBox(height: 8),

                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Edad',
                  value: age == null ? 'No registrada' : '$age años',
                  color: cs.primary,
                ),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Cuenta',
                  value: 'Google',
                  color: cs.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}
