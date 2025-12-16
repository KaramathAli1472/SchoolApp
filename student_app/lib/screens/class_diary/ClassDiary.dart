import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassDiaryScreen extends StatefulWidget {
  const ClassDiaryScreen({Key? key}) : super(key: key);

  @override
  State<ClassDiaryScreen> createState() => _ClassDiaryScreenState();
}

class _ClassDiaryScreenState extends State<ClassDiaryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> entries = [];

  // optional filters (aap baad me student ke classId se set kar sakte ho)
  String? classIdFilter;
  DateTime? dateFilter;

  @override
  void initState() {
    super.initState();
    _fetchDiary();
  }

  Future<void> _fetchDiary() async {
    setState(() {
      isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('classDiary')
          .orderBy('date', descending: true); // string date ya timestamp dono chalega [web:125]

      if (classIdFilter != null && classIdFilter!.isNotEmpty) {
        query = FirebaseFirestore.instance
            .collection('classDiary')
            .where('classId', isEqualTo: classIdFilter)
            .orderBy('date', descending: true);
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'classId': d['classId'] ?? '',
          'date': d['date'],
          'subject': d['subject'] ?? '',
          'title': d['title'] ?? '',
          'details': d['details'] ?? '',
          'homework': d['homework'] ?? '',
        };
      }).toList();

      if (dateFilter != null) {
        final target = _dateOnly(dateFilter!);
        data = data.where((e) {
          final value = e['date'];
          if (value == null) return false;
          if (value is Timestamp) {
            final dt = _dateOnly(value.toDate());
            return dt == target;
          }
          if (value is String) {
            // YYYY-MM-DD string
            return value == _dateToString(target);
          }
          return false;
        }).toList();
      }

      setState(() {
        entries = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading class diary: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }
    if (value is String) {
      try {
        final d = DateTime.parse(value);
        return '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/'
            '${d.year}';
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }

  String _dateToString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Diary'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const _EmptyView()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final item = entries[index];
          return _DiaryCard(
            title: item['title'],
            subject: item['subject'],
            classId: item['classId'],
            date: _formatDate(item['date']),
            details: item['details'],
            homework: item['homework'],
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No diary entries yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final String title;
  final String subject;
  final String classId;
  final String date;
  final String details;
  final String homework;

  const _DiaryCard({
    Key? key,
    required this.title,
    required this.subject,
    required this.classId,
    required this.date,
    required this.details,
    required this.homework,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.isNotEmpty;
    final hasHomework = homework.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book, color: Colors.indigo, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTitle ? title : subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$classId • $subject',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (details.isNotEmpty)
              Text(
                details,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            if (hasHomework) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      homework,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
