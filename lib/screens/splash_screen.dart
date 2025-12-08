import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/screens/login_screen.dart';


/// A simple splash screen that decides where to route the user after a brief
/// delay. If the user is authenticated it navigates to the appropriate
/// dashboard based on their role; otherwise it moves to the onboarding/login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final Color primaryBlue = const Color(0xFF072957);
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _navigate);
  }



  void _navigate() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.access_time_filled, size: 80, color: primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Techezm Attendance Portal',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}