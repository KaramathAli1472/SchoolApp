import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    required this.classId,
  });

  final String classId;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Firestore day keys order
  final List<String> _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri'];
  final Map<String, String> _dayLabels = const {
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dayKeys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _ttStream() {
    return FirebaseFirestore.instance
        .collection('timetables')
        .doc(widget.classId)
        .snapshots();
  }

  String _periodTitle(String key) {
    if (key == 'ip') return 'Intervention';
    if (key.startsWith('br')) return 'Break';
    if (key == 'ct') return 'CT';
    final num = int.tryParse(key.substring(1)) ?? 0;
    return 'Period $num';
  }

  String _periodTime(String key) {
    switch (key) {
      case 'ct':
        return '07:30 AM - 07:55 AM';
      case 'p1':
        return '07:55 AM - 08:35 AM';
      case 'ip':
        return '08:35 AM - 09:10 AM';
      case 'br1':
        return '09:10 AM - 09:35 AM';
      case 'p2':
        return '09:35 AM - 10:15 AM';
      case 'p3':
        return '10:15 AM - 10:55 AM';
      case 'br2':
        return '10:55 AM - 11:00 AM';
      case 'p4':
        return '11:00 AM - 11:40 AM';
      case 'p5':
        return '11:40 AM - 12:20 PM';
      case 'br3':
        return '12:20 PM - 12:25 PM';
      case 'p6':
        return '12:25 PM - 01:05 PM';
      case 'p7':
        return '01:05 PM - 01:45 PM';
      default:
        return '';
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
          'Timetable',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                indicator: BoxDecoration(
                  color: Colors.indigoAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _dayKeys
                    .map((k) => Tab(text: _dayLabels[k] ?? k))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ttStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No timetable found'));
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};

          return TabBarView(
            controller: _tabController,
            children: _dayKeys.map((dayKey) {
              final dayMapRaw = data[dayKey];
              if (dayMapRaw is! Map<String, dynamic>) {
                return const Center(child: Text('No periods'));
              }

              // Order matching admin panel: CT, P1, IP, Break1, P2, P3, Break2, P4, P5, Break3, P6, P7
              final periodOrder = [
                'ct',
                'p1',
                'ip',
                'br1',
                'p2',
                'p3',
                'br2',
                'p4',
                'p5',
                'br3',
                'p6',
                'p7',
              ];

              final periods = periodOrder
                  .where((k) =>
              dayMapRaw[k] != null &&
                  dayMapRaw[k].toString().isNotEmpty)
                  .toList();

              if (periods.isEmpty) {
                return const Center(child: Text('No periods'));
              }

              return ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: periods.length,
                itemBuilder: (context, index) {
                  final key = periods[index];
                  final subject = dayMapRaw[key].toString();
                  final title = _periodTitle(key);
                  final timeRange = _periodTime(key);

                  final leftTime = timeRange.split('-').first.trim();

                  final isBreak = key.startsWith('br');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              leftTime,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBreak
                                            ? Colors.orange
                                            : Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeRange,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subject,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
