import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:techezm_attendance_portal/models/attendance_model.dart';
import 'package:techezm_attendance_portal/models/user_model.dart';
import 'package:techezm_attendance_portal/services/export_service.dart';

import '../../providers/auth_provider.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String? _selectedEmployeeUid;
  DateTimeRange? _dateRange;
  List<AttendanceRecord> _records = [];

  bool _loading = false;

  int _presentCount = 0;
  int _absentCount = 0;

  final Color primaryBlue = const Color(0xFF072957);

  // -----------------------------------------------------------------------
  // 📅 DATE RANGE SELECTOR
  // -----------------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _dateRange = picked);
  }

  // -----------------------------------------------------------------------
  // 📥 LOAD RECORDS + PRESENT / ABSENT LOGIC
  // -----------------------------------------------------------------------
  Future<void> _loadRecords() async {
    if (_selectedEmployeeUid == null) return;

    setState(() => _loading = true);

    final firestore = ref.read(firestoreServiceProvider);

    // Get ALL records for employee (no date filter)
    // Get ALL records for employee (no date filter)
    final allRecords = await firestore.getAttendanceRecords(
      employeeId: _selectedEmployeeUid!,
    );

    // Filter by date range if selected
    List<AttendanceRecord> filteredRecords = allRecords;
    if (_dateRange != null) {
      final start = DateTime(
          _dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
      final end = DateTime(
          _dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day)
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1)); // End of the day

      filteredRecords = allRecords.where((r) {
        return r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            r.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    _records = filteredRecords;

    int present = _records.length;
    int absent = 0;

    final df = DateFormat('yyyy-MM-dd');
    final presentDates = _records.map((e) => df.format(e.date)).toSet();

    // -----------------------------------------------------------
    // MODE A: EMPLOYEE selected + NO DATE RANGE
    // -----------------------------------------------------------
    // -----------------------------------------------------------
    // MODE A: EMPLOYEE selected + NO DATE RANGE
    // -----------------------------------------------------------
    if (_dateRange == null) {
      final user = await firestore.getUser(_selectedEmployeeUid!);
      if (user != null) {
        // Normalize start date to midnight
        DateTime rawStart = user.createdAt;
         if (_records.isNotEmpty && _records.first.date.isBefore(rawStart)) {
           rawStart = _records.first.date;
        }
        DateTime start = DateTime(rawStart.year, rawStart.month, rawStart.day);

        // Normalize today to midnight
        final now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        int abs = 0;

        for (DateTime d = start;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {

          // Skip Sundays
          if (d.weekday == DateTime.sunday) continue;

          final dayStr = df.format(d);

          // If no present record → Absent day
          if (!presentDates.contains(dayStr)) {
            abs++;
          }
        }
        absent = abs;
      }
    }

    // -----------------------------------------------------------
    // MODE B: Employee + DATE RANGE selected
    // -----------------------------------------------------------
    // -----------------------------------------------------------
    // MODE B: Employee + DATE RANGE selected
    // -----------------------------------------------------------
    if (_dateRange != null) {
      int abs = 0;
      
      // Normalize selected range dates
      final rangeStart = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
      final rangeEnd = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);

      // Determine effective start date (Employee Join Date)
      // We don't want to mark them absent before they joined.
      final user = await firestore.getUser(_selectedEmployeeUid!);
      DateTime effectiveStart = rangeStart; 
      
      if (user != null) {
        DateTime rawJoinDate = user.createdAt;
        // If they have attendance *before* their creation date (migrated data?), use that.
        if (allRecords.isNotEmpty && allRecords.first.date.isBefore(rawJoinDate)) {
          rawJoinDate = allRecords.first.date;
        }
        
        final joinDate = DateTime(rawJoinDate.year, rawJoinDate.month, rawJoinDate.day);
        
        // If the selected range starts BEFORE they joined, we should only count absents
        // starting from their join date.
        if (joinDate.isAfter(rangeStart)) {
          effectiveStart = joinDate;
        }
      }

      for (DateTime d = rangeStart;
      !d.isAfter(rangeEnd);
      d = d.add(const Duration(days: 1))) {

        // Skip days before they joined
        if (d.isBefore(effectiveStart)) continue;

        // Skip Sundays
        if (d.weekday == DateTime.sunday) continue;

        final dayStr = df.format(d);

        if (!presentDates.contains(dayStr)) {
          abs++;
        }
      }

      absent = abs;
    }

    // Update UI
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _loading = false;
    });
  }

  // -----------------------------------------------------------------------
  // 📥 DOWNLOAD REPORT (CSV)
  // -----------------------------------------------------------------------
  // -----------------------------------------------------------------------
  // 📥 DOWNLOAD REPORT (CSV)
  // -----------------------------------------------------------------------
  Future<void> _downloadReport() async {
    if (_records.isEmpty || _selectedEmployeeUid == null) return;

    try {
      final firestore = ref.read(firestoreServiceProvider);
      // Fetch user name for filename
      final user = await firestore.getUser(_selectedEmployeeUid!);
      final name = user?.name ?? "Unknown_Employee";

      await ExportService().exportToCsv(
        _records, 
        name,
        _presentCount,
        _absentCount
      );
      
      // No snackbar needed as Share dialog provides feedback/action
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export Failed: $e")),
      );
    }
  }





  // -----------------------------------------------------------------------
  // 📱 UI
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text(
          "Attendance Reports",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------
            // EMPLOYEE DROPDOWN
            // ---------------------------------------------------
            FutureBuilder<List<UserModel>>(
              future: ref.read(firestoreServiceProvider).getEmployees(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final employees = snapshot.data!;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryBlue.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedEmployeeUid,
                      hint: const Text("Select Employee"),
                      items: employees
                          .map(
                            (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeUid = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ---------------------------------------------------
            // DATE RANGE SELECTOR
            // ---------------------------------------------------
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateRange == null
                          ? "Choose date range"
                          : "${df.format(_dateRange!.start)} → ${df.format(_dateRange!.end)}",
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateRange,
                    child:
                    Text("Select", style: TextStyle(color: primaryBlue)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---------------------------------------------------
            // LOAD BUTTON
            // ---------------------------------------------------
            // ---------------------------------------------------
            // BUTTONS
            // ---------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selectedEmployeeUid == null
                        ? null
                        : _loadRecords,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Load Records",
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_selectedEmployeeUid == null || _records.isEmpty)
                        ? null
                        : _downloadReport,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Download",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------
            // PRESENT / ABSENT SUMMARY (Always visible after loading)
            // ---------------------------------------------------
            if (_selectedEmployeeUid != null && _records.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Present",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                        Text("$_presentCount",
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("Absent",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red)),
                        Text("$_absentCount",
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

            // ---------------------------------------------------
            // RECORD LIST
            // ---------------------------------------------------
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                  ? const Center(
                child: Text("No attendance records found"),
              )
                  : ListView.builder(
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final r = _records[index];
                  return _buildRecordCard(r, df);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // RECORD CARD UI
  // -----------------------------------------------------------------------
  // -----------------------------------------------------------------------
  // RECORD CARD UI
  // -----------------------------------------------------------------------
  Widget _buildRecordCard(AttendanceRecord r, DateFormat df) {
    final tf = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: const Color(0xff0a3d62),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Title
            Text(
              df.format(r.date),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Entry (blue)
            _buildInfoRow(
              Icons.login,
              "Entry",
              r.entryTime != null ? tf.format(r.entryTime!) : "--",
              iconColor: const Color(0xff0a3d62),
            ),

            // 🔸 Exit (orange)
            _buildInfoRow(
              Icons.logout,
              "Exit",
              r.exitTime != null ? tf.format(r.exitTime!) : "--",
              iconColor: Colors.orange,
            ),

            // 🟣 Total Hours (purple)
            _buildInfoRow(
              Icons.timer,
              "Total Hours",
              r.totalHours != null ? r.totalHours!.toStringAsFixed(2) : "--",
              iconColor: Colors.deepPurple,
            ),

            // ☕ Break Start
            _buildInfoRow(
              Icons.coffee,
              "Break Start",
              r.breakExitTime != null ? tf.format(r.breakExitTime!) : "--",
              iconColor: Colors.brown,
            ),

            // ☕ Break End
            _buildInfoRow(
              Icons.coffee_outlined,
              "Break End",
              r.breakReturnTime != null ? tf.format(r.breakReturnTime!) : "--",
              iconColor: Colors.brown[300]!,
            ),

            // 🟢 / 🔴 Inside Area
            _buildInfoRow(
              Icons.my_location,
              "Inside Area",
              r.insideArea ? "Yes" : "No",
              iconColor: r.insideArea ? Colors.green : Colors.red,
              valueColor: r.insideArea ? Colors.green : Colors.red,
            ),

            // 🟢 / 🔴 WiFi matched
            _buildInfoRow(
              Icons.wifi,
              "Wi-Fi Matched",
              r.wifiMatched ? "Yes" : "No",
              iconColor: r.wifiMatched ? Colors.green : Colors.red,
              valueColor: r.wifiMatched ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // Icon Row Helper
  // -------------------------------
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color iconColor = Colors.black87,
    Color valueColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
