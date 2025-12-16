// lib/screens/assignments/assignments_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  final String classId;
  final String studentId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _assignmentsStream() {
    debugPrint('📡 AssignmentsScreen classId => $classId');

    return FirebaseFirestore.instance
        .collection('homework')
    // yahan filter hata diya, sirf test ke liye
    // .where('classId', isEqualTo: classId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF5A6CD0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brandColor,
        title: const Text(
          'Assignments',
          style: TextStyle(
            color: Colors.white,      // ← yahan white colour
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,        // back button bhi white
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _assignmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading assignments',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No assignments found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final String title =
              (data['title'] ?? 'Assignment').toString();
              final String subject =
              (data['subject'] ?? 'Subject').toString();
              final String description =
              (data['description'] ?? '').toString();
              final String deadline =
              (data['deadline'] ?? '').toString();
              final String givenDate =
              (data['date'] ?? '').toString();
              final String uploadedBy =
              (data['uploadedBy'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deadline.isNotEmpty
                              ? 'Due: $deadline'
                              : 'No deadline',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (givenDate.isNotEmpty)
                          Text(
                            'Given: $givenDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const Spacer(),
                        if (uploadedBy.isNotEmpty)
                          Text(
                            uploadedBy,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
