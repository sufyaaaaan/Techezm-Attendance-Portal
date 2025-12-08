import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/models/attendance_model.dart';
import 'auth_provider.dart';

/// Provider to fetch attendance records for the current authenticated user.
final attendanceRecordsProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final user = await ref.watch(currentUserModelProvider.future);
  if (user == null) return [];
  final firestore = ref.read(firestoreServiceProvider);
  return firestore.getAttendanceRecords(employeeId: user.id);
});