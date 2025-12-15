import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  /// Student ki classId load karo (students/{uid} se)
  Future<String?> _loadStudentClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();

    if (!snap.exists) return null;

    final data = snap.data() as Map<String, dynamic>;
    return data['classId'] as String?;
  }

  /// Notices ka stream (sirf is class ke notices)
  Stream<QuerySnapshot<Map<String, dynamic>>> _noticesStream(
  String classId,
) {
  return FirebaseFirestore.instance
      .collection('notices')
      // .where('classId', isEqualTo: classId)
      .orderBy('date', descending: true)
      .snapshots();
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadStudentClass(),
      builder: (context, classSnap) {
        if (classSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notices')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (classSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notices')),
            body: Center(child: Text('Error: ${classSnap.error}')),
          );
        }

        final classId = classSnap.data;
        if (classId == null || classId.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notices')),
            body: const Center(
              child: Text('Class not found for this student'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Notices - $classId'),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _noticesStream(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No notices for your class'),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final title = data['title'] ?? 'Notice';
                  final description = data['description'] ?? '';
                  final dateStr = data['date'] ?? '';
                  final classLabel = data['classId'] ?? 'All';

                  final shortDate = dateStr.toString().split('T').first;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.campaign, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Class: $classLabel',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              Text(
                                shortDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
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
      },
    );
  }
}

