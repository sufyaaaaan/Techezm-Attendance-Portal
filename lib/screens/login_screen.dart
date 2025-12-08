import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';
import 'package:techezm_attendance_portal/screens/admin/admin_dashboard.dart';
import 'package:techezm_attendance_portal/screens/employee/employee_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAdmin = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  // ============================
  // ⭐ Modern Error Dialog
  // ============================
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Login Error",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFF072957),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleRole() {
    setState(() {
      _isAdmin = !_isAdmin;
    });
  }

  // ============================
  // ⭐ LOGIN FUNCTION
  // ============================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final auth = ref.read(authServiceProvider);

      // Firebase sign in
      final user = await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        _showErrorDialog("Login failed. Please try again.");
        return;
      }

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // Employee?
      final emp = await firestore.collection("employees").doc(uid).get();
      if (emp.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
        );
        return;
      }

      // Admin?
      final admin = await firestore.collection("users").doc(uid).get();
      if (admin.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
        return;
      }

      _showErrorDialog("No user profile found in the database.");
    } catch (e) {
      _showErrorDialog(
        e.toString()
            .replaceAll("firebase_auth/", "")
            .replaceAll("-", " "),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ============================
  // ⭐ Input Decoration
  // ============================
  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF072957), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF072957);
    final title = _isAdmin ? "Admin Login" : "Employee Login";

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 28),

              // CARD
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),

                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputStyle("Email"),
                        validator: (val) =>
                        val == null || val.isEmpty ? "Enter email" : null,
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputStyle("Password"),
                        validator: (val) =>
                        val == null || val.isEmpty ? "Enter password" : null,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            "Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _toggleRole,
                        child: Text(
                          _isAdmin
                              ? "Switch to Employee Login"
                              : "Switch to Admin Login",
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
