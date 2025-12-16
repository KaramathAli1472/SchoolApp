// lib/screens/event/event_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({Key? key}) : super(key: key);

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  // agar baad me calendar lagana ho to yeh use ho sakta hai
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // key: YYYY-MM-DD -> list of items
  Map<String, List<Map<String, dynamic>>> _itemsByDate = {};

  bool _loading = true;
  String _activeTab = 'events'; // 'events' | 'holidays'

  // 0 ka matlab "no filter" (All)
  int _selectedMonth = 0;
  int _selectedYear = 0;

  @override
  void initState() {
    super.initState();
    _loadEventsFromFirestore();
  }

  Future<void> _loadEventsFromFirestore() async {
    try {
      final snap = await _db
          .collection('schoolEvents')
          .orderBy('date', descending: false)
          .get();

      debugPrint('Loaded docs: ${snap.docs.length}');

      final Map<String, List<Map<String, dynamic>>> map = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        debugPrint('doc ${doc.id} -> $data');

        final dateStr = (data['date'] ?? '') as String;
        if (dateStr.isEmpty) continue;

        final item = {
          'id': doc.id,
          'type': data['type'] ?? 'event',
          'title': data['title'] ?? '',
          'subtitle': data['subtitle'] ?? '',
          'date': dateStr,
          'endDate': data['endDate'] ?? dateStr,
          'tagLabel': data['tagLabel'] ??
              ((data['type'] == 'holiday') ? 'Holiday' : 'Event'),
          'tagColor': data['tagColor'] ?? '#009966',
        };

        map.putIfAbsent(dateStr, () => []);
        map[dateStr]!.add(item);
      }

      debugPrint('itemsByDate: $map');

      setState(() {
        _itemsByDate = map;
        _loading = false;

        // default filter: first doc ka month/year
        if (map.isNotEmpty) {
          final firstKey = map.keys.first; // "2025-12-01"
          final dt = DateTime.tryParse(firstKey);
          if (dt != null) {
            _selectedMonth = dt.month;
            _selectedYear = dt.year;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  // month/year + tab ke hisab se saare items (0 = no filter)
  List<Map<String, dynamic>> _allItemsFiltered() {
    return _itemsByDate.entries
        .expand((e) => e.value)
        .where((item) {
      final dateStr = item['date'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return false;

      // month filter
      if (_selectedMonth != 0 && dt.month != _selectedMonth) {
        return false;
      }
      // year filter
      if (_selectedYear != 0 && dt.year != _selectedYear) {
        return false;
      }

      if (_activeTab == 'events' && item['type'] != 'event') return false;
      if (_activeTab == 'holidays' && item['type'] != 'holiday') {
        return false;
      }
      return true;
    })
        .toList()
      ..sort(
            (a, b) =>
            (a['date'] as String).compareTo(b['date'] as String),
      );
  }

  // future calendar markers helper (abhi use nahi ho raha)
  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final key = _formatDateKey(day);
    final list = _itemsByDate[key] ?? [];
    if (_activeTab == 'events') {
      return list.where((e) => e['type'] == 'event').toList();
    } else {
      return list.where((e) => e['type'] == 'holiday').toList();
    }
  }

  Color _parseColor(String hex) {
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse('0x$h'));
    } catch (_) {
      return const Color(0xFF009966);
    }
  }

  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthLabel(date.month);
    final year = date.year.toString();
    return '$day $month $year';
  }

  String _monthLabel(int m) {
    const labels = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return labels[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _allItemsFiltered();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF516BE8),
        title: const Text(
          'Event Calendar',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Tabs
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _activeTab = 'events';
                      }),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _activeTab == 'events'
                              ? Colors.indigoAccent
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Events',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _activeTab == 'events'
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _activeTab = 'holidays';
                      }),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _activeTab == 'holidays'
                              ? Colors.indigoAccent
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Holidays',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _activeTab == 'holidays'
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Month / Year dropdown + All
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: _selectedMonth == 0
                      ? DateTime.now().month
                      : _selectedMonth,
                  items: List.generate(12, (i) {
                    final m = i + 1;
                    return DropdownMenuItem(
                      value: m,
                      child: Text(_monthLabel(m)),
                    );
                  }),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedMonth = val;
                    });
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedYear == 0
                      ? DateTime.now().year
                      : _selectedYear,
                  items: List.generate(6, (i) {
                    final y = DateTime.now().year - 1 + i;
                    return DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
                    );
                  }),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedYear = val;
                    });
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // All = koi month/year filter nahi
                    setState(() {
                      _selectedMonth = 0;
                      _selectedYear = 0;
                    });
                  },
                  child: const Text(
                    'All',
                    style: TextStyle(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),

          // Range title for first item
          if (selectedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _buildRangeTitle(selectedItems[0]),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // List
          Expanded(
            child: selectedItems.isEmpty
                ? const Center(
              child: Text(
                'No items.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                final color = _parseColor(
                    item['tagColor'] as String? ?? '#009966');
                return _EventCard(
                  tagLabel:
                  item['tagLabel'] as String? ?? '',
                  title: item['title'] as String? ?? '',
                  subtitle:
                  item['subtitle'] as String? ?? '',
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildRangeTitle(Map<String, dynamic> item) {
    final start = DateTime.tryParse(item['date'] as String? ?? '');
    final end = DateTime.tryParse(item['endDate'] as String? ?? '');
    if (start == null) return '';
    if (end == null || start.isAtSameMomentAs(end)) {
      return _formatDisplayDate(start);
    }
    return '${_formatDisplayDate(start)} - ${_formatDisplayDate(end)}';
  }
}

class _EventCard extends StatelessWidget {
  final String tagLabel;
  final String title;
  final String subtitle;
  final Color color;

  const _EventCard({
    Key? key,
    required this.tagLabel,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.only(
            left: 12, right: 12, top: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tagLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
