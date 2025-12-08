import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:techezm_attendance_portal/models/attendance_model.dart';
import 'package:techezm_attendance_portal/models/user_model.dart';

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
    final records = await firestore.getAttendanceRecords(
      employeeId: _selectedEmployeeUid!,
    );

    _records = records;

    int present = records.length;
    int absent = 0;

    final df = DateFormat('yyyy-MM-dd');
    final presentDates = records.map((e) => df.format(e.date)).toSet();

    // -----------------------------------------------------------
    // MODE A: EMPLOYEE selected + NO DATE RANGE
    // -----------------------------------------------------------
    if (_dateRange == null && records.isNotEmpty) {
      // First attendance ever
      DateTime first = records.first.date;
      // Current day
      DateTime today = DateTime.now();

      int abs = 0;

      for (DateTime d = first;
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

    // -----------------------------------------------------------
    // MODE B: Employee + DATE RANGE selected
    // -----------------------------------------------------------
    if (_dateRange != null) {
      int abs = 0;

      for (DateTime d = _dateRange!.start;
      !d.isAfter(_dateRange!.end);
      d = d.add(const Duration(days: 1))) {

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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedEmployeeUid == null
                  ? null
                  : _loadRecords,
              child: const Text("Load Records",
                  style: TextStyle(color: Colors.white)),
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
  Widget _buildRecordCard(AttendanceRecord r, DateFormat df) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          df.format(r.date),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("Entry: ${r.entryTime != null ? DateFormat('HH:mm').format(r.entryTime!) : '--'}"),
            Text("Exit: ${r.exitTime != null ? DateFormat('HH:mm').format(r.exitTime!) : '--'}"),
            Text("Total Hours: ${r.totalHours?.toStringAsFixed(2) ?? '--'}"),
            Text("Inside Area: ${r.insideArea ? 'Yes' : 'No'}"),
            Text("Wi-Fi Matched: ${r.wifiMatched ? 'Yes' : 'No'}"),
          ],
        ),
      ),
    );
  }
}
