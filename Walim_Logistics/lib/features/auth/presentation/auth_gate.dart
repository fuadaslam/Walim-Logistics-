import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/auth/presentation/login_screen.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/rider_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/leader_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/admin_dashboard.dart';

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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final role = authState.profile!.role;
    print('AuthGate: Routing for role: $role');

    switch (role) {
      case 'Admin':
        return const AdminDashboard();
      case 'Supervisor':
      case 'Operations Manager':
      case 'Finance Manager':
      case 'Business Development':
      case 'IT_Dev':
      case 'HR':
        return const SupervisorDashboard();
      case 'Leader':
        return const LeaderDashboard();
      case 'Rider':
        return const RiderDashboard();
      default:
        print('AuthGate: Unknown role "$role", defaulting to debug view');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unknown or Unhandled Role: "$role"'),
                const SizedBox(height: 16),
                const Text('Please contact administrator to map this role.'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: const Text('Logout & Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RiderDashboard()),
                  ),
                  child: const Text('Continue to Rider Dashboard (Emergency)'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
