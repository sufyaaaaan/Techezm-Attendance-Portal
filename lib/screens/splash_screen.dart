import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';
import 'package:techezm_attendance_portal/screens/admin/admin_dashboard.dart';
import 'package:techezm_attendance_portal/screens/employee/employee_dashboard.dart';
import 'package:techezm_attendance_portal/screens/login_screen.dart';
import 'package:techezm_attendance_portal/services/firestore_service.dart';

/// A splash screen that handles session restoration and role-based routing.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final Color primaryBlue = const Color(0xFF072957);
  String _statusMessage = "Loading...";

  @override
  void initState() {
    super.initState();
    _handleStartupLogic();
  }

  Future<void> _handleStartupLogic() async {
    // 1. Minimum Splash Duration (for branding)
    // We start this timer immediately.
    final minSplashDuration = Future.delayed(const Duration(seconds: 2));

    // 2. Listen for the FIRST valid auth state emission.
    // authStateChanges() fires immediately with the current state.
    final authState = FirebaseAuth.instance.authStateChanges().first;

    try {
      // Wait for both timer and auth check to complete
      final results = await Future.wait([minSplashDuration, authState]);
      final User? user = results[1] as User?;

      if (user == null) {
        // No session found -> Login
        _navigateToLogin();
        return;
      }

      // 3. User is logged in -> Fetch Role
      if (mounted) setState(() => _statusMessage = "Restoring session...");
      
      final firestore = ref.read(firestoreServiceProvider);
      final userModel = await firestore.getUser(user.uid);

      if (userModel != null) {
        if (!mounted) return;
        if (userModel.role == 'admin') {
          _navigate(const AdminDashboard());
        } else {
          _navigate(const EmployeeDashboard());
        }
      } else {
        // Authenticated but no record in DB? Edge case.
        print("User authenticated but no Firestore doc found for uid: ${user.uid}");
        // We could sign them out here to be safe
        await FirebaseAuth.instance.signOut();
        _navigateToLogin();
      }

    } catch (e) {
      print("Error during splash startup: $e");
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigate(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.access_time_filled, size: 80, color: primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Techezm Attendance Portal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}