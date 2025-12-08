import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: unnecessary_import
import 'firebase_options.dart';
import 'package:techezm_attendance_portal/screens/splash_screen.dart';

/// The root widget of the application.
///
/// This widget ensures Firebase is initialized before rendering the rest of
/// the application. It wraps the child widgets with a [ProviderScope]
/// enabling Riverpod state management throughout the widget tree.
class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  // Initialize Firebase asynchronously before building the app.
  Future<FirebaseApp> _initializeFirebase() async {
    // When using FlutterFire CLI, firebase_options.dart provides the
    // configuration for the current platform.
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Techezm Attendance Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        home: FutureBuilder(
          future: _initializeFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Firebase initialization error: ${snapshot.error}'),
                ),
              );
            }
            // When Firebase is initialized successfully, show the splash screen.
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}