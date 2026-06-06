import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.init();

  final appState = AppState(storage: storage, notifications: notifications);
  await appState.load();
  await notifications.requestPermissions();

  runApp(MedisyncApp(appState: appState));
}

class MedisyncApp extends StatelessWidget {
  const MedisyncApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Medisync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Routes between onboarding and the main shell based on persisted state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<AppState>().isOnboarded;
    return onboarded ? const HomeShell() : const OnboardingScreen();
  }
}
