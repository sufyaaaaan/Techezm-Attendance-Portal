import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:techezm_attendance_portal/models/attendance_model.dart';
import 'package:techezm_attendance_portal/providers/auth_provider.dart';
import 'package:techezm_attendance_portal/providers/settings_provider.dart';
import 'package:techezm_attendance_portal/services/attendance_service.dart';
import 'package:techezm_attendance_portal/screens/login_screen.dart';
import 'package:techezm_attendance_portal/screens/employee/attendance_history_screen.dart';
import 'package:techezm_attendance_portal/screens/employee/profile_screen.dart';

class EmployeeDashboard extends ConsumerStatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  ConsumerState<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboard> {
  final Color primaryBlue = const Color(0xFF072957);

  AttendanceValidationResult? _validation;
  AttendanceRecord? _todayRecord;

  bool _loadingValidation = false;
  bool _recordLoading = false;

  bool _markingAttendance = false; // 🔥 NEW: loading overlay flag

  late ProviderSubscription _authSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authSubscription = ref.listenManual<AsyncValue>(
        currentUserModelProvider,
            (prev, next) {
          if (next is AsyncData && next.value != null && mounted) {
            _refreshStatus();
          }
        },
      );

      final current = ref.read(currentUserModelProvider);
      if (current is AsyncData && current.value != null) {
        _refreshStatus();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // REFRESH STATUS
  // ---------------------------------------------------------------------------
  Future<void> _refreshStatus() async {
    if (!mounted) return;

    setState(() {
      _loadingValidation = true;
      _recordLoading = true;
    });

    final userAsync = ref.read(currentUserModelProvider);
    if (userAsync is! AsyncData || userAsync.value == null) {
      setState(() {
        _loadingValidation = false;
        _recordLoading = false;
      });
      return;
    }

    final user = userAsync.value!;
    final geofence = await ref.read(geofenceSettingsProvider.future);
    final wifi = await ref.read(wifiSettingsProvider.future);

    if (!mounted) return;

    if (geofence != null && wifi != null) {
      final result = await AttendanceService().validate(
        geofence: geofence,
        allowedWifiName: wifi.wifiName,
      );

      if (!mounted) return;
      setState(() => _validation = result);
    }

    final firestore = ref.read(firestoreServiceProvider);
    final record = await firestore.getAttendanceRecordForDate(
      user.id,
      DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _todayRecord = record;
      _loadingValidation = false;
      _recordLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // CONFIRM DIALOG
  // ---------------------------------------------------------------------------
  Future<bool> _confirmAction(String type) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $type"),
        content: Text("Are you sure you want to mark $type?"),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            child: Text("Yes, $type"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ---------------------------------------------------------------------------
  // MARK ATTENDANCE + SHOW LOADING OVERLAY
  // ---------------------------------------------------------------------------
  Future<void> _markAttendance(bool isEntry) async {
    final confirm = await _confirmAction(isEntry ? "Entry" : "Exit");
    if (!confirm || !mounted) return;

    setState(() => _markingAttendance = true); // 🔥 SHOW OVERLAY

    final userAsync = ref.read(currentUserModelProvider);
    if (userAsync is! AsyncData || userAsync.value == null) {
      setState(() => _markingAttendance = false);
      return;
    }

    final user = userAsync.value!;
    final geofence = await ref.read(geofenceSettingsProvider.future);
    final wifi = await ref.read(wifiSettingsProvider.future);

    final validation = await AttendanceService().validate(
      geofence: geofence!,
      allowedWifiName: wifi!.wifiName,
    );

    setState(() => _validation = validation);

    if (!validation.insideArea || !validation.wifiMatched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be inside geofence AND on allowed WiFi')),
      );

      setState(() => _markingAttendance = false);
      return;
    }

    final firestore = ref.read(firestoreServiceProvider);
    final record = await firestore.recordAttendance(
      employeeId: user.id,
      isEntry: isEntry,
      insideArea: validation.insideArea,
      wifiMatched: validation.wifiMatched,
    );

    setState(() {
      _todayRecord = record;
      _markingAttendance = false; // 🔥 HIDE LOADING
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEntry ? "Entry marked!" : "Exit marked!")),
    );

    _refreshStatus();
  }

  // ---------------------------------------------------------------------------
  // LOADING OVERLAY WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildLoadingOverlay() {
    if (!_markingAttendance) return const SizedBox();

    return Container(
      color: Colors.black38,
      child: const Center(
        child: SizedBox(
          height: 70,
          width: 70,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,

        // ====== TITLE: Employee Name ======
        title: Consumer(
          builder: (context, ref, _) {
            final userAsync = ref.watch(currentUserModelProvider);

            if (userAsync is AsyncData && userAsync.value != null) {
              return Text(
                userAsync.value!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF072957),
                ),
              );
            }

            return const Text(
              "Employee Dashboard",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF072957),
              ),
            );
          },
        ),

        actions: [
          // ====== HISTORY BUTTON ======
          IconButton(
            icon: const Icon(Icons.history, color: Colors.green),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
            ),
          ),

          // ====== PROFILE BUTTON ======
          IconButton(
            icon: const Icon(Icons.person, color: Colors.blue),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),

          // ====== LOGOUT BUTTON ======
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Confirm Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF072957),
                    ),
                  ),
                  content: const Text(
                    "Are you sure you want to log out?",
                    style: TextStyle(fontSize: 15),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),

                  actions: [
                    // CANCEL
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFF072957),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),

                    // LOGOUT
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(currentUserModelProvider);

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                  );
                }
              }
            },
          ),
        ],
      ),


      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshStatus,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTodaySummary(df, tf),
                const SizedBox(height: 22),
                _buildLiveStatusCard(tf),
              ],
            ),
          ),

          // 🔥 OVERLAY HERE
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPONENTS
  // ---------------------------------------------------------------------------
  Widget _buildTodaySummary(DateFormat df, DateFormat tf) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today (${df.format(DateTime.now())})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _recordLoading
              ? const LinearProgressIndicator()
              : Column(
            children: [
              _infoRow("Entry",
                  _todayRecord?.entryTime != null ? tf.format(_todayRecord!.entryTime!) : "--"),
              _infoRow("Exit",
                  _todayRecord?.exitTime != null ? tf.format(_todayRecord!.exitTime!) : "--"),
              _infoRow(
                "Total Hours",
                _todayRecord?.totalHours != null
                    ? _todayRecord!.totalHours!.toStringAsFixed(2)
                    : "--",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusCard(DateFormat tf) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          if (_loadingValidation)
            const LinearProgressIndicator()
          else if (_validation != null) ...[
            _statusRow(Icons.location_on, "Accuracy",
                "${_validation!.locationAccuracy.toStringAsFixed(2)} m"),
            _statusRow(Icons.wifi, "Connected Wi-Fi",
                _validation!.currentWifiName ?? "--"),
            _statusRow(Icons.my_location, "Inside Allowed Area",
                _validation!.insideArea ? "Yes" : "No",
                color: _validation!.insideArea ? Colors.green : Colors.red),
            _statusRow(Icons.check_circle, "Wi-Fi Matched",
                _validation!.wifiMatched ? "Yes" : "No",
                color:
                _validation!.wifiMatched ? Colors.green : Colors.red),
          ] else
            const Text("Unable to determine status",
                style: TextStyle(color: Colors.black54)),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _modernButton(
                  label: "Mark Entry",
                  enabled: _todayRecord?.entryTime == null,
                  onTap: () => _markAttendance(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _modernButton(
                  label: "Mark Exit",
                  enabled: _todayRecord?.entryTime != null &&
                      _todayRecord?.exitTime == null,
                  onTap: () => _markAttendance(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI Helpers -------------------------------------------------------
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: primaryBlue, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String title, String value,
      {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _modernButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [Color(0xff0a3d62), Color(0xff3c6382)])
              : const LinearGradient(colors: [Colors.grey, Colors.grey]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: const Color(0xff0a3d62).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(2, 3),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
      ),
    );
  }
}
