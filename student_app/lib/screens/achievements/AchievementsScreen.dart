import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Map<String, dynamic>> achievements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAchievements();
  }

  Future<void> _fetchAchievements() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('achievements')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        achievements = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'date': data['date'] ?? '',
            'type': data['type'] ?? '',
            'studentName': data['studentName'] ?? '',
            'className': data['className'] ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching achievements: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : achievements.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No achievements yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (achievement['studentName']
                                .toString()
                                .isNotEmpty ||
                                achievement['className']
                                    .toString()
                                    .isNotEmpty)
                              Text(
                                '${achievement['studentName']} • ${achievement['className']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (achievement['description']
                      .toString()
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Text(
                        achievement['description'],
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(
                            achievement['date'].toString()),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                              achievement['type'].toString()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          achievement['type']
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'school':
        return Colors.blue.shade400;
      case 'student':
        return Colors.green.shade400;
      case 'sports':
        return Colors.orange.shade400;
      case 'cultural':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}
