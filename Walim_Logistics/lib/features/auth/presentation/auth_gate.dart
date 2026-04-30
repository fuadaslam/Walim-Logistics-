import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/auth/presentation/login_screen.dart';
import 'package:walim_logistics/features/dashboard/presentation/main_dashboard_shell.dart';
import 'package:walim_logistics/core/widgets/loading_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      return const LoginScreen();
    }

    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${authState.error}'),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (authState.profile == null) {
      return const AppLoadingScreen(message: 'Verifying session...');
    }

    // Now all authenticated users go through the MainDashboardShell
    // which handles role-based content and tab navigation.
    return const MainDashboardShell();
  }
}
