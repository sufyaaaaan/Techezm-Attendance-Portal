import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techezm_attendance_portal/models/user_model.dart';
import 'package:techezm_attendance_portal/models/geofence_settings.dart';
import 'package:techezm_attendance_portal/models/wifi_settings.dart';
import 'package:techezm_attendance_portal/models/attendance_model.dart';

/// Service responsible for interacting with Cloud Firestore.
///
/// This class centralizes queries and updates related to users, settings and
/// attendance. It exposes higher level methods that hide Firestore
/// implementation details from the rest of the app.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves the geofence settings from Firestore. If no settings exist,
  /// returns null.
  Future<GeofenceSettings?> getGeofenceSettings() async {
    final doc = await _firestore.collection('settings').doc('geofence').get();
    if (doc.exists) {
      return GeofenceSettings.fromMap(doc.data()!);
    }
    return null;
  }

  /// Saves or updates the geofence settings.
  Future<void> setGeofenceSettings(GeofenceSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('geofence')
        .set(settings.toMap());
  }

  /// Retrieves Wi‑Fi settings from Firestore. If none exist, returns null.
  Future<WifiSettings?> getWifiSettings() async {
    final doc = await _firestore.collection('settings').doc('wifi').get();
    if (doc.exists) {
      return WifiSettings.fromMap(doc.data()!);
    }
    return null;
  }

  /// Saves or updates the Wi‑Fi settings.
  Future<void> setWifiSettings(WifiSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('wifi')
        .set(settings.toMap());
  }

  /// Retrieves all employees. Admins can use this to populate lists.
  Future<List<UserModel>> getEmployees() async {
    final snapshot = await _firestore.collection('employees').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Retrieves attendance records for an [employeeId]. Optionally provide
  /// [startDate] and [endDate] to filter by date range.
  Future<List<AttendanceRecord>> getAttendanceRecords({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('attendance')
        .doc(employeeId)
        .collection('records');

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }
    final snapshot = await query.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data()))
        .toList();
  }

  /// Retrieves a single attendance record for an [employeeId] on a specific
  /// [date] (yyyy‑MM‑dd). Returns null if none exists.
  Future<AttendanceRecord?> getAttendanceRecordForDate(

      String employeeId, DateTime date) async {
    final docId = _dateToDocId(date);
    final doc = await _firestore
        .collection('attendance')
        .doc(employeeId)
        .collection('records')
        .doc(docId)
        .get();

    if (doc.exists) {
      return AttendanceRecord.fromMap(doc.data()!);
    }

    // Return an empty record instead of null
    return AttendanceRecord(
      date: date,
      entryTime: null,
      exitTime: null,
      insideArea: false,
      wifiMatched: false,
      totalHours: 0,
    );
  }


  /// Records attendance for an employee. If [isEntry] is true, sets the entry
  /// time; otherwise sets the exit time and computes total hours. Returns the
  /// updated [AttendanceRecord].
  Future<AttendanceRecord> recordAttendance({
    required String employeeId,
    required bool isEntry,
    required bool insideArea,
    required bool wifiMatched,
  }) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final docId = _dateToDocId(date);
    final docRef = _firestore
        .collection('attendance')
        .doc(employeeId)
        .collection('records')
        .doc(docId);
    final doc = await docRef.get();
    AttendanceRecord? existing;
    if (doc.exists) {
      existing = AttendanceRecord.fromMap(doc.data()!);
    }
    DateTime? entryTime = existing?.entryTime;
    DateTime? exitTime = existing?.exitTime;
    bool inside = insideArea;
    bool wifiOk = wifiMatched;
    double? totalHours;
    if (isEntry) {
      // Prevent overriding existing entry
      entryTime ??= now;
    } else {
      // On exit, record the exit time and compute duration
      exitTime ??= now;
      if (entryTime != null) {
        final duration = exitTime.difference(entryTime);
        totalHours = duration.inMinutes / 60;
      }
    }
    final record = AttendanceRecord(
      date: date,
      entryTime: entryTime,
      exitTime: exitTime,
      insideArea: inside,
      wifiMatched: wifiOk,
      totalHours: totalHours,
    );
    await docRef.set(record.toMap());
    return record;
  }

  /// Counts the number of employees and calculates attendance statistics for
  /// today. Returns a map with keys `totalEmployees`, `present`, `absent`,
  /// `late`.
  Future<Map<String, int>> getDashboardStats({Duration? lateThreshold}) async {
    lateThreshold ??= const Duration(minutes: 15);
    final totalEmployees = (await _firestore.collection('employees').get()).size;
    final today = DateTime.now();
    int present = 0;
    int late = 0;
    // iterate employees
    final employees = await _firestore.collection('employees').get();
    for (final emp in employees.docs) {
      final record = await getAttendanceRecordForDate(emp.id, today);
      if (record != null && record.entryTime != null) {
        present++;
        // If entry time is after office start + lateThreshold, count as late.
        // For simplicity assume office starts at 09:00 local time.
        final officeStart = DateTime(
            record.entryTime!.year,
            record.entryTime!.month,
            record.entryTime!.day,
            9,
            0);
        if (record.entryTime!.isAfter(officeStart.add(lateThreshold))) {
          late++;
        }
      }
    }
    final absent = totalEmployees - present;
    return {
      'totalEmployees': totalEmployees,
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  /// Helper to convert a [date] into a doc id (yyyy‑MM‑dd).
  String _dateToDocId(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}