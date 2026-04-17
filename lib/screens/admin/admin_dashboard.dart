import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';
import 'package:techezm_attendance_portal/screens/admin/employee_form_screen.dart';
import 'package:techezm_attendance_portal/screens/admin/attendance_report_screen.dart';
import 'package:techezm_attendance_portal/screens/admin/settings_screen.dart';
import 'package:techezm_attendance_portal/screens/login_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  // -------------------------------------------------------------
  // LOGOUT CONFIRMATION + FULL LOGOUT
  // -------------------------------------------------------------
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final Color primaryBlue = const Color(0xFF072957);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // 1️⃣ Firebase logout
      await ref.read(authServiceProvider).signOut();

      // 2️⃣ Clear Auth providers
      ref.invalidate(currentUserModelProvider);

      // 3️⃣ Navigate to Login (remove all previous screens)
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    }
  }

  // -------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.read(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, int>>(
        future: firestore.getDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading dashboard: \n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    DashboardCard(
                      label: 'Total Employees',
                      value: stats['totalEmployees']?.toString() ?? '-',
                      icon: Icons.people_alt_outlined,
                      color: Colors.blueAccent,
                    ),
                    DashboardCard(
                      label: 'Present Today',
                      value: stats['present']?.toString() ?? '-',
                      icon: Icons.verified_user_outlined,
                      color: Colors.green,
                    ),
                    DashboardCard(
                      label: 'Absent Today',
                      value: stats['absent']?.toString() ?? '-',
                      icon: Icons.highlight_off_outlined,
                      color: Colors.redAccent,
                    ),
                    DashboardCard(
                      label: 'Late Arrivals',
                      value: stats['late']?.toString() ?? '-',
                      icon: Icons.access_time_outlined,
                      color: Colors.orange,
                    ),
                    DashboardCard(
                      label: 'On Leave',
                      value: stats['leave']?.toString() ?? '-',
                      icon: Icons.beach_access_outlined,
                      color: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Management",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                ModernListTile(
                  icon: Icons.person_add,
                  title: "Add Employee",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
                  ),
                ),

                ModernListTile(
                  icon: Icons.list_alt,
                  title: "Attendance Reports",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                  ),
                ),

                ModernListTile(
                  icon: Icons.location_on,
                  title: "Location Settings",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// DASHBOARD CARD WIDGET
// -------------------------------------------------------------
class DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// MODERN LIST TILE
// -------------------------------------------------------------
class ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ModernListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF072957),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: Colors.white, size: 26),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}
