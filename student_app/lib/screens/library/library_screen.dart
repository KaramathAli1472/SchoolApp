import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryScreen extends StatelessWidget {
  final String classId; // current student ka classId (e.g. class_6)

  const LibraryScreen({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('libraryBooks')
        .orderBy('title'); // class filter hata ke

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ Library error: ${snapshot.error}');
            return const Center(child: Text('Failed to load books'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No books available'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = data['title'] ?? '';
              final author = data['author'] ?? '';
              final subject = data['subject'] ?? '';
              final rackNo = data['rackNo'] ?? '';
              final total = data['totalCopies'] ?? 0;
              final available = data['availableCopies'] ?? 0;

              return ListTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20, // pehle 18 tha
                  ),
                ),
                subtitle: Text(
                  [
                    if (author.isNotEmpty) author,
                    if (subject.isNotEmpty) subject,
                    if (rackNo.isNotEmpty) 'Rack: $rackNo',
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 16, // default se bada
                    color: Colors.black87,
                  ),
                ),
                trailing: Text(
                  '$available / $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // copies text bhi bada
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
