import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:techezm_attendance_portal/providers/attendance_provider.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(attendanceRecordsProvider);
    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fc),

      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance records yet.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              itemCount: records.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final r = records[index];

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
                        _infoRow(
                          Icons.login,
                          "Entry",
                          r.entryTime != null ? tf.format(r.entryTime!) : "--",
                          iconColor: const Color(0xff0a3d62),
                        ),

                        // 🔸 Exit (orange)
                        _infoRow(
                          Icons.logout,
                          "Exit",
                          r.exitTime != null ? tf.format(r.exitTime!) : "--",
                          iconColor: Colors.orange,
                        ),

                        // 🟣 Total Hours (purple)
                        _infoRow(
                          Icons.timer,
                          "Total Hours",
                          r.totalHours != null
                              ? r.totalHours!.toStringAsFixed(2)
                              : "--",
                          iconColor: Colors.deepPurple,
                        ),

                        // 🟢 / 🔴 Inside Area
                        _infoRow(
                          Icons.my_location,
                          "Inside Area",
                          r.insideArea ? "Yes" : "No",
                          iconColor: r.insideArea ? Colors.green : Colors.red,
                          valueColor:
                          r.insideArea ? Colors.green : Colors.red,
                        ),

                        // 🟢 / 🔴 WiFi matched
                        _infoRow(
                          Icons.wifi,
                          "Wi-Fi Matched",
                          r.wifiMatched ? "Yes" : "No",
                          iconColor: r.wifiMatched ? Colors.green : Colors.red,
                          valueColor:
                          r.wifiMatched ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },

          loading: () => const Center(child: CircularProgressIndicator()),

          error: (e, st) => Center(
            child: Text(
              "Error: $e",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------
  // Icon Row Helper
  // -------------------------------
  Widget _infoRow(
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
