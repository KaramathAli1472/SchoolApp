import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('date', descending: true)
          .get(); // [web:125]

      final data = snapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'title': d['title'] ?? '',
          'description': d['description'] ?? '',
          'classId': d['classId'] ?? '',
          'date': d['date'],
        };
      }).toList();

      setState(() {
        items = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      setState(() => isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const _EmptyAnnouncements()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final a = items[index];
            return _AnnouncementCard(
              title: a['title'],
              description: a['description'],
              classId: a['classId'],
              date: _formatDate(a['date']),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyAnnouncements extends StatelessWidget {
  const _EmptyAnnouncements({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Center(
          child: Text(
            'No announcements yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String description;
  final String classId;
  final String date;

  const _AnnouncementCard({
    Key? key,
    required this.title,
    required this.description,
    required this.classId,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAllClasses = classId.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.campaign, color: Colors.deepOrange, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAllClasses
                                  ? Colors.indigo.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isAllClasses ? 'All classes' : classId,
                              style: TextStyle(
                                fontSize: 11,
                                color: isAllClasses
                                    ? Colors.indigo.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
