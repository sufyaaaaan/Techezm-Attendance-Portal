import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _loadingName = false;
  bool _loadingPassword = false;

  String? _nameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  void _loadCurrentName() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  Future<void> _updateName() async {
    setState(() {
      _loadingName = true;
      _nameError = null;
    });

    try {
      await ref.read(authServiceProvider).updateProfileName(
        _nameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      setState(() => _nameError = e.toString());
    } finally {
      setState(() => _loadingName = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loadingPassword = true;
      _passwordError = null;
    });

    try {
      await ref.read(authServiceProvider).updatePassword(
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      _passwordController.clear();
      _passwordConfirmController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      setState(() => _passwordError = e.toString());
    } finally {
      setState(() => _loadingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8fc),

      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _title("Update Name"),
            _sectionCard(
              children: [
                _textField(
                  controller: _nameController,
                  label: "Name",
                ),
                if (_nameError != null)
                  _errorText(_nameError!),
                const SizedBox(height: 12),
                _primaryButton(
                  label: "Save Name",
                  loading: _loadingName,
                  onTap: _updateName,
                ),
              ],
            ),

            const SizedBox(height: 26),

            _title("Change Password"),
            _sectionCard(
              children: [
                _textField(
                  controller: _passwordController,
                  label: "New Password",
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _passwordConfirmController,
                  label: "Confirm Password",
                  obscure: true,
                ),
                if (_passwordError != null)
                  _errorText(_passwordError!),
                const SizedBox(height: 12),
                _primaryButton(
                  label: "Change Password",
                  loading: _loadingPassword,
                  onTap: _updatePassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _title(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: const Color(0xff0a3d62),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: loading
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : const LinearGradient(
            colors: [Color(0xff0a3d62), Color(0xff3c6382)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading
              ? []
              : [
            BoxShadow(
              color: const Color(0xff0a3d62).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }
}
