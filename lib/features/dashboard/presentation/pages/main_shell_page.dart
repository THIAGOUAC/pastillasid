import 'package:flutter/material.dart';

import '../../../../features/calendar/presentation/pages/calendar_page.dart';
import '../../../../features/chatbot/presentation/pages/chatbot_page.dart';
import '../../../../features/medications/presentation/pages/medication_list_page.dart';
import '../../../../features/pharmacies/presentation/pages/pharmacy_map_page.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';
import 'home_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CalendarPage(),
    const MedicationListPage(),
    const PharmacyMapPage(),
    const SettingsPage(),
  ];

  final List<String> _titles = const [
    'Inicio',
    'Calendario',
    'Medicamentos',
    'Farmacias',
    'Perfil',
  ];

  void _changePage(int index) {
    setState(() => _currentIndex = index);
  }

  void _openChatbot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const ChatbotPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatbot,
        backgroundColor: cs.primary,
        icon: const Icon(Icons.medical_services, color: Colors.white),
        label: const Text(
          'Dr. Gerbacio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changePage,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medicinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy),
            label: 'Farmacias',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
