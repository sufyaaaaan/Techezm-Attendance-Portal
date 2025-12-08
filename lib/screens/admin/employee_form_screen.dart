import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  ConsumerState<EmployeeFormScreen> createState() =>
      _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final username = _usernameController.text.trim();
      final email = "$username@techezm.com";

      final user = await authService.createEmployee(
        name: _nameController.text.trim(),
        username: username,
        email: email,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee created: ${user.username}')),
      );

      _formKey.currentState?.reset();
      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration _fieldStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: const Color(0xFF072957).withOpacity(0.4),
          width: 1.2,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF072957),
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.6,
        ),
      ),

      labelStyle: const TextStyle(fontSize: 15),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text('Add Employee', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Text(
                    "Create Employee",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF072957),
                    ),
                  ),
                  const SizedBox(height: 25),

                  TextFormField(
                    controller: _nameController,
                    decoration: _fieldStyle("Employee Name"),
                    validator: (v) => v!.isEmpty ? "Please enter name" : null,
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _usernameController,
                    decoration: _fieldStyle("Username"),
                    validator: (v) => v!.isEmpty ? "Please enter username" : null,
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _fieldStyle("Password"),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Please enter password";
                      if (v.length < 6) return "Password must be at least 6 characters";
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _createEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF072957),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Create Employee",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
