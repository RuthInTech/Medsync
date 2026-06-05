import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import 'clinician_tab.dart';
import 'education_tab.dart';
import 'home_tab.dart';
import 'reports_tab.dart';
import 'settings_tab.dart';

/// Root navigation shell with the five primary destinations.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    HomeTab(),
    EducationTab(),
    ReportsTab(),
    ClinicianTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(context.watch<AppState>().language);
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
              icon: const Icon(Icons.assessment_outlined),
              selectedIcon: const Icon(Icons.assessment),
              label: l.t('report')),
          NavigationDestination(
              icon: const Icon(Icons.local_hospital_outlined),
              selectedIcon: const Icon(Icons.local_hospital),
              label: l.t('clinic')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.t('settings')),
        ],
      ),
    );
  }
}
