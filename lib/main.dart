import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_state.dart';
import 'services/auth_service.dart';
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

class MedisyncApp extends StatefulWidget {
  const MedisyncApp({super.key, required this.appState});
  final AppState appState;

  @override
  State<MedisyncApp> createState() => MedisyncAppState();

  static MedisyncAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MedisyncAppState>()!;
}

class MedisyncAppState extends State<MedisyncApp> {
  final _authNotifier = ValueNotifier<_AuthStatus>(_AuthStatus.checking);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = AuthService();
    final loggedIn = await auth.isLoggedIn();
    if (!loggedIn) {
      _authNotifier.value = _AuthStatus.loggedOut;
      return;
    }
    // Clinicians skip onboarding entirely
    final role = await auth.getRole();
    if (role == 'clinician') {
      _authNotifier.value = _AuthStatus.loggedIn;
      return;
    }
    final onboarded = await auth.isOnboarded();
    _authNotifier.value =
        onboarded ? _AuthStatus.loggedIn : _AuthStatus.needsOnboarding;
  }

  void onLoginSuccess() async {
    final auth = AuthService();
    final role = await auth.getRole();
    if (role == 'clinician') {
      _authNotifier.value = _AuthStatus.loggedIn;
      return;
    }
    final onboarded = await auth.isOnboarded();
    _authNotifier.value =
        onboarded ? _AuthStatus.loggedIn : _AuthStatus.needsOnboarding;
  }

  void onOnboardingComplete() {
    _authNotifier.value = _AuthStatus.loggedIn;
  }

  void onLogout() async {
    await AuthService().logout();
    await widget.appState.reset();
    _authNotifier.value = _AuthStatus.loggedOut;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appState,
      child: MaterialApp(
        title: 'Medisync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: ValueListenableBuilder<_AuthStatus>(
          valueListenable: _authNotifier,
          builder: (context, status, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (status) {
                _AuthStatus.checking => const _SplashScreen(),
                _AuthStatus.loggedOut => LoginScreen(
                    key: const ValueKey('login'),
                    onLoginSuccess: onLoginSuccess,
                  ),
                _AuthStatus.needsOnboarding => OnboardingScreen(
                    key: const ValueKey('onboarding'),
                    onComplete: onOnboardingComplete,
                  ),
                _AuthStatus.loggedIn =>
                  const HomeShell(key: ValueKey('shell')),
              },
            );
          },
        ),
      ),
    );
  }
}

enum _AuthStatus { checking, loggedOut, needsOnboarding, loggedIn }

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}
