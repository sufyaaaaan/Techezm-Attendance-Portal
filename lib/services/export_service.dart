import 'dart:io';
import 'package:csv/csv.dart' as csv;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techezm_attendance_portal/models/attendance_model.dart';

class ExportService {
  /// Generates a CSV file from the given [records] and triggers a share dialog.
  /// [employeeName] is used for the filename.
  Future<void> exportToCsv(
      List<AttendanceRecord> records,
      String employeeName,
      int totalPresent,
      int totalAbsent,
      ) async {
    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('HH:mm');

    // 1. Create Header Rows with Summary
    List<List<dynamic>> rows = [
      ["Attendance Report for $employeeName"],
      ["Total Present", totalPresent],
      ["Total Absent", totalAbsent],
      [], // Empty row for spacing
      [
        "Date",
        "Entry Time",
        "Exit Time",
        "Break Start",
        "Break End",
        "Total Hours",
        "Inside Area",
        "WiFi Matched",
        "Late"
      ]
    ];

    // 2. Add Data Rows
    // Sort records by date descending (newest first) or ascending? 
    // Usually reports are chronological. Let's keep them as passed (usually from Firestore meaning sorted).
    // If we want to ensure sorting, we can do it here, but the caller should usually handle it.
    
    for (var r in records) {
      rows.add([
        df.format(r.date),
        r.entryTime != null ? tf.format(r.entryTime!) : "--",
        r.exitTime != null ? tf.format(r.exitTime!) : "--",
        r.breakExitTime != null ? tf.format(r.breakExitTime!) : "--",
        r.breakReturnTime != null ? tf.format(r.breakReturnTime!) : "--",
        r.totalHours?.toStringAsFixed(2) ?? "0.00",
        r.insideArea ? "Yes" : "No",
        r.wifiMatched ? "Yes" : "No",
        r.isLate ? "Yes" : "No",
      ]);
    }

    // 3. Convert to CSV String
    String csvData = const csv.ListToCsvConverter().convert(rows);

    // 4. Save to Temporary File
    final directory = await getTemporaryDirectory();
    final fileName = "${employeeName.replaceAll(' ', '_')}_Attendance_Report.csv";
    final path = "${directory.path}/$fileName";
    final file = File(path);
    await file.writeAsString(csvData);

    // 5. Share File
    await Share.shareXFiles([XFile(path)], text: "Attendance Report for $employeeName");
  }
}
