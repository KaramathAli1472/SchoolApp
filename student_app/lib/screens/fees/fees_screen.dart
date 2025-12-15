import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({
    super.key,
    required this.studentDocId,
  });

  final String studentDocId;

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  static const List<String> _years = [
    '2025-2026',
    '2024-2025',
    '2023-2024',
  ];

  String _selectedYear = _years.first;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _feesStream() {
    return FirebaseFirestore.instance
        .collection('fees')
        .doc(widget.studentDocId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFF5A6CD0);
    const Color brandAccent = Color(0xFF5A6CD0);
    const String currency = 'INR';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _feesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No fee record found'));
          }

          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          final String studentName =
          (data['studentName'] ?? 'Student Name').toString();
          final String className =
          (data['className'] ?? 'Class').toString();
          final String photoUrl =
          (data['photoUrl'] ?? '').toString();

          final num totalRaw =
          (data['totalFee'] is num) ? data['totalFee'] as num : 0;
          final num paidRaw =
          (data['totalPaid'] is num) ? data['totalPaid'] as num : 0;

          final double total = totalRaw.toDouble();
          final double paid = paidRaw.toDouble();
          final double balance = total - paid;
          final double percentPaid =
          total > 0 ? (paid / total * 100) : 0.0;

          // current due fee (screenshot jaisa ek hi card)
          final num dueRaw =
          (data['dueAmount'] is num) ? data['dueAmount'] as num : balance;
          final double dueAmount = dueRaw.toDouble();
          final String dueDate =
          (data['dueDate'] ?? '').toString(); // "01 Sep 2025" etc.

          // transaction history
          final List<dynamic> rawHistory =
              (data['paymentHistory'] as List?) ?? [];
          final List<Map<String, dynamic>> records = rawHistory
              .whereType<Map<String, dynamic>>()
              .toList()
            ..sort((a, b) {
              final String ad = (a['date'] ?? '').toString();
              final String bd = (b['date'] ?? '').toString();
              return bd.compareTo(ad);
            });

          return Column(
            children: [
              // TOP YELLOW + CARD
              Container(
                decoration: BoxDecoration(
                  color: brandYellow,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // appbar row with pic + year
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  className,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedYear,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  dropdownColor: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: _years
                                      .map(
                                        (y) => DropdownMenuItem<String>(
                                      value: y,
                                      child: Text(y),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedYear = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // big white total card
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Total Fee Balance',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${percentPaid.toStringAsFixed(2)} % Paid',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$currency ${balance.toStringAsFixed(2)} /${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BODY
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    // Fee Payment Accounts
                    const Text(
                      'Fee Payment Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fee',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$currency ${dueAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Due Date : ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      dueDate,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              // pay now action
                            },
                            child: const Text(
                              'Pay Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // More Options
                    const Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Transaction History row ONLY
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: const Icon(
                              Icons.history,
                              size: 26,
                              color: Colors.grey,
                            ),
                            title: const Text(
                              'Transaction History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // nayi screen pe full transaction list open karo
                              // abhi ke liye simple dialog:
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (_) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Transaction History',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (records.isEmpty)
                                          const Text(
                                            'No transactions yet',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          )
                                        else
                                          ...records.map((item) {
                                            final String title =
                                            (item['title'] ??
                                                'Payment')
                                                .toString();
                                            final String date =
                                            (item['date'] ?? '')
                                                .toString();
                                            final double amount =
                                            (item['amount'] is num)
                                                ? (item['amount']
                                            as num)
                                                .toDouble()
                                                : 0;
                                            return ListTile(
                                              contentPadding:
                                              EdgeInsets.zero,
                                              title: Text(title),
                                              subtitle: Text(date),
                                              trailing: Text(
                                                '$currency ${amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.w700,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
