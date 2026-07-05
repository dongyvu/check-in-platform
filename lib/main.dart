import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:sign/config/supabase_config.dart';
import 'package:sign/features/admin/screens/admin_main_screen.dart';
import 'package:sign/features/auth/screens/login_screen.dart';
import 'package:sign/features/student/screens/student_main_screen.dart';
import 'package:sign/models/app_profile.dart';
import 'package:sign/repositories/sign_repository.dart';
import 'package:sign/shared/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await appSettingsController.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettingsController,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final useDynamic =
                appSettingsController.useDynamicColor &&
                lightDynamic != null &&
                darkDynamic != null;
            final lightScheme = useDynamic
                ? lightDynamic.harmonized()
                : ColorScheme.fromSeed(
                    seedColor: appSettingsController.seedColor,
                  );
            final darkScheme = useDynamic
                ? darkDynamic.harmonized()
                : ColorScheme.fromSeed(
                    seedColor: appSettingsController.seedColor,
                    brightness: Brightness.dark,
                  );

            return MaterialApp(
              title: '签到平台',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
              darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
              themeMode: appSettingsController.themeMode,
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repository = SignRepository();
  late Future<AppProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repository.fetchCurrentProfile(preferCache: true);
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final profile = await _repository.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(profile);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const LoginScreen();
        }

        return profile.isAdmin ? const AdminMainScreen() : const MainScreen();
      },
    );
  }
}
