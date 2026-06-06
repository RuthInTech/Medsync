import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'clinician_tab.dart';
import 'education_tab.dart';
import 'home_tab.dart';
import 'reports_tab.dart';
import 'settings_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String? _role;

  @override
  void initState() {
    super.initState();
    AuthService().getRole().then((r) {
      if (mounted) setState(() => _role = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_role == 'clinician') {
      return _ClinicianShell(index: _index, onIndexChanged: (i) => setState(() => _index = i));
    }

    return _PatientShell(index: _index, onIndexChanged: (i) => setState(() => _index = i));
  }
}

class _PatientShell extends StatelessWidget {
  const _PatientShell({required this.index, required this.onIndexChanged});
  final int index;
  final ValueChanged<int> onIndexChanged;

  static const _tabs = [
    HomeTab(),
    EducationTab(),
    ReportsTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = AppLocalizations(app.language);
    final safeIndex = index.clamp(0, _tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: _tabs),
      bottomNavigationBar: _NavBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onIndexChanged,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l.t('today')),
          NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: l.t('learn')),
          NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: l.t('report')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.t('settings')),
        ],
      ),
    );
  }
}

class _ClinicianShell extends StatelessWidget {
  const _ClinicianShell({required this.index, required this.onIndexChanged});
  final int index;
  final ValueChanged<int> onIndexChanged;

  static const _tabs = [
    ClinicianTab(),
    ClinicianSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, _tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: _tabs),
      bottomNavigationBar: _NavBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onIndexChanged,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Patients'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
