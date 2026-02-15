import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single attendance record.
///
/// Attendance is recorded per employee and date. Both entry and exit times
/// are stored along with boolean flags indicating whether the employee was
/// inside the allowed geofence and connected to the correct Wi‑Fi network.
class AttendanceRecord {
  final DateTime date;
  final DateTime? entryTime;
  final DateTime? breakExitTime;
  final DateTime? breakReturnTime;

  final DateTime? exitTime;
  final bool insideArea;
  final bool wifiMatched;
  final double? totalHours;

  AttendanceRecord({
    required this.date,
    required this.entryTime,
    required this.exitTime,
    required this.insideArea,
    required this.wifiMatched,
    required this.totalHours,
    this.breakExitTime,
    this.breakReturnTime,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data) {
    return AttendanceRecord(
      date: (data['date'] as Timestamp).toDate(),
      entryTime: data['entryTime'] != null
          ? (data['entryTime'] as Timestamp).toDate()
          : null,
      exitTime: data['exitTime'] != null
          ? (data['exitTime'] as Timestamp).toDate()
          : null,
      insideArea: data['insideArea'] ?? false,
      wifiMatched: data['wifiMatched'] ?? false,
      totalHours: (data['totalHours'] as num?)?.toDouble(),
      breakExitTime: data['breakExitTime'] != null
          ? (data['breakExitTime'] as Timestamp).toDate()
          : null,
      breakReturnTime: data['breakReturnTime'] != null
          ? (data['breakReturnTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'entryTime': entryTime != null ? Timestamp.fromDate(entryTime!) : null,
      'exitTime': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
      'insideArea': insideArea,
      'wifiMatched': wifiMatched,
      'totalHours': totalHours,
      'breakExitTime': breakExitTime != null ? Timestamp.fromDate(breakExitTime!) : null,
      'breakReturnTime': breakReturnTime != null ? Timestamp.fromDate(breakReturnTime!) : null,
    };
  }

  /// Returns true if entry time is after 2:10 PM (14:10).
  bool get isLate {
    if (entryTime == null) return false;
    final h = entryTime!.hour;
    final m = entryTime!.minute;
    // Late if hour > 14 OR (hour == 14 AND minute > 10)
    return h > 14 || (h == 14 && m > 10);
  }
}