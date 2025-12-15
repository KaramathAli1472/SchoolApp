import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({
    super.key,
    required this.studentDocId, // e.g. "OneIrvsFtylvy3oA5N2E"
    required this.classId,      // e.g. "class_2"
  });

  final String studentDocId;
  final String classId;

  // Saare date docs: attendance/2025-12-12, 2025-12-13, ...
  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots();
  }

  Color _badgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF00B894); // green
      case 'absent':
        return const Color(0xFFE53935); // red
      case 'week off':
        return const Color(0xFFFF9800); // orange
      case 'holiday':
        return const Color(0xFFFFC107); // amber
      default:
        return Colors.grey;
    }
  }

  String _badgeLetter(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'P';
      case 'absent':
        return 'A';
      case 'week off':
        return 'W';
      case 'holiday':
        return 'H';
      default:
        return '-';
    }
  }

  // "2025-12-09" -> "09 Dec 2025, Tue"
  String _formatDate(String ymd) {
    try {
      final date = DateTime.parse(ymd);
      return DateFormat('dd MMM yyyy, EEE').format(date);
    } catch (_) {
      return ymd;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _attendanceStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No attendance records found'),
            );
          }

          final docs = snapshot.data!.docs;
          final List<_AttendanceRow> rows = [];

          for (final doc in docs) {
            final dateId = doc.id; // "2025-12-12"
            final data = doc.data(); // class_2, class_3, ...

            if (!data.containsKey(classId)) continue;
            final classBlock = data[classId];
            if (classBlock is! Map<String, dynamic>) continue;
            if (!classBlock.containsKey(studentDocId)) continue;

            final stuData = classBlock[studentDocId];
            if (stuData is! Map<String, dynamic>) continue;

            final status = (stuData['status'] ?? '') as String;
            final cid = (stuData['classId'] ?? classId) as String;

            rows.add(
              _AttendanceRow(
                dateString: dateId,
                status: status,
                classId: cid,
              ),
            );
          }

          if (rows.isEmpty) {
            return const Center(
              child: Text('No attendance records found'),
            );
          }

          // Latest date first
          rows.sort((a, b) => b.dateString.compareTo(a.dateString));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                height: 1,
                thickness: 1,                 // line ki motai
                color: Colors.black,        // dark line (black jaisa)
              ),
            ),
            itemBuilder: (context, index) {
              final row = rows[index];
              final status = row.status;
              final color = _badgeColor(status);
              final letter = _badgeLetter(status);
              final isWeekOff =
                  status.toLowerCase() == 'week off' || letter == 'W';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(row.dateString),
                          style: const TextStyle(
                            fontSize: 17, // bigger date text
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isWeekOff)
                        Text(
                          '-- WeekOff --',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        )
                      else
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // bigger badge text
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AttendanceRow {
  final String dateString;
  final String status;
  final String classId;

  _AttendanceRow({
    required this.dateString,
    required this.status,
    required this.classId,
  });
}
