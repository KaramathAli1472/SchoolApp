import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ObjectiveExamListScreen extends StatelessWidget {
  final String classId;

  const ObjectiveExamListScreen({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('objectiveExams')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Objective Exams',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6079EA),
        iconTheme: const IconThemeData(color: Colors.white), // back icon white
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ ObjectiveExams error: ${snapshot.error}');
            return const Center(
              child: Text(
                'Failed to load exams',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // 👈 agar background dark hai
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.quiz_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No exams available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = (data['title'] ?? '') as String;
              final subject = (data['subject'] ?? '') as String;
              final cls = (data['classId'] ?? '') as String;
              final totalMarks = (data['totalMarks'] ?? 0) as int;
              final duration = (data['durationMinutes'] ?? 0) as int;
              final isPublished = (data['isPublished'] ?? false) as bool;

              DateTime? startTime;
              DateTime? endTime;
              final rawStart = data['startTime'];
              final rawEnd = data['endTime'];
              if (rawStart != null && rawStart is Timestamp) {
                startTime = rawStart.toDate();
              }
              if (rawEnd != null && rawEnd is Timestamp) {
                endTime = rawEnd.toDate();
              }

              final bool isScheduled = startTime != null && endTime != null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6079EA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.quiz,
                      color: Color(0xFF6079EA),
                      size: 26,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$subject • $cls',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marks: $totalMarks • Duration: $duration min',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      if (isScheduled && startTime != null && endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Schedule: '
                                '${_formatDate(startTime)} - ${_formatTime(endTime)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isPublished ? 'Live' : 'Draft',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPublished ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: yahan se ObjectiveExamScreen me navigate karna hai
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (_) => ObjectiveExamScreen(examId: docs[index].id),
                    // ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
