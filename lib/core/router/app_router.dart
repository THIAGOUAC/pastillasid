import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/dashboard/presentation/pages/main_shell_page.dart';
import '../../features/medicine_scan/presentation/pages/scan_medicine_page.dart';
import '../../features/medications/presentation/pages/medication_detail_page.dart';
import '../../features/medications/presentation/pages/medication_form_page.dart';
import '../../features/medications/presentation/pages/medication_list_page.dart';
import '../../features/pharmacies/presentation/pages/pharmacy_map_page.dart';
import '../../features/profile/presentation/pages/onboarding_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/onboarding-profile',
      name: 'onboarding-profile',
      builder: (context, state) => const OnboardingProfilePage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainShellPage(),
    ),
    GoRoute(
      path: '/medications',
      name: 'medications',
      builder: (context, state) => const MedicationListPage(),
    ),
    GoRoute(
      path: '/medications/new',
      name: 'medications-new',
      builder: (context, state) => const MedicationFormPage(),
    ),
    GoRoute(
      path: '/medications/edit/:id',
      name: 'medications-edit',
      builder: (context, state) {
        final medicationId = state.pathParameters['id']!;

        return MedicationFormPage(medicationId: medicationId);
      },
    ),
    GoRoute(
      path: '/medications/:id',
      name: 'medication-detail',
      builder: (context, state) {
        final medicationId = state.pathParameters['id']!;

        return MedicationDetailPage(medicationId: medicationId);
      },
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarPage(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanMedicinePage(),
    ),
    GoRoute(
      path: '/pharmacies',
      name: 'pharmacies',
      builder: (context, state) => const PharmacyMapPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
