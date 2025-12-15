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

  /// ===== FEES STREAM =====
  Stream<DocumentSnapshot<Map<String, dynamic>>> _feesStream() {
    return FirebaseFirestore.instance
        .collection('fees')
        .doc(widget.studentDocId)
        .snapshots();
  }

  /// ===== STUDENT STREAM (PHOTO YAHI SE AAYEGI) =====
  Stream<DocumentSnapshot<Map<String, dynamic>>> _studentStream() {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentDocId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF5A6CD0);
    const String currency = 'INR';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      /// ===== FEES STREAM =====
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _feesStream(),
        builder: (context, feeSnap) {
          if (feeSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (feeSnap.hasError) {
            return Center(child: Text('Error: ${feeSnap.error}'));
          }

          if (!feeSnap.hasData || !feeSnap.data!.exists) {
            return const Center(child: Text('No fee record found'));
          }

          final Map<String, dynamic> feeData =
              feeSnap.data!.data() ?? {};

          /// ===== FEES DATA =====
          final double total =
          (feeData['totalFee'] is num)
              ? (feeData['totalFee'] as num).toDouble()
              : 0;

          final double paid =
          (feeData['totalPaid'] is num)
              ? (feeData['totalPaid'] as num).toDouble()
              : 0;

          final double balance = total - paid;
          final double percentPaid =
          total > 0 ? (paid / total * 100) : 0;

          final double dueAmount =
          (feeData['dueAmount'] is num)
              ? (feeData['dueAmount'] as num).toDouble()
              : balance;

          final String dueDate =
          (feeData['dueDate'] ?? '').toString();

          final List<Map<String, dynamic>> records =
          ((feeData['paymentHistory'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .toList()
            ..sort((a, b) =>
                (b['date'] ?? '').compareTo(a['date'] ?? ''));

          /// ===== STUDENT STREAM (PHOTO + NAME) =====
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _studentStream(),
            builder: (context, stuSnap) {
              final Map<String, dynamic> studentData =
                  stuSnap.data?.data() ?? {};

              final String studentName =
              (studentData['name'] ?? 'Student Name').toString();

              final String className =
              (studentData['class'] ?? 'Class').toString();

              final String studentPhotoUrl =
              (studentData['photoUrl'] ?? '').toString();

              debugPrint('PHOTO URL => $studentPhotoUrl');

              return Column(
                children: [
                  /// ===== HEADER =====
                  Container(
                    decoration: const BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: Colors.white,
                                  onPressed: () => Navigator.pop(context),
                                ),

                                /// ===== STUDENT PHOTO =====
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                  studentPhotoUrl.isNotEmpty
                                      ? NetworkImage(studentPhotoUrl)
                                      : null,
                                  child: studentPhotoUrl.isEmpty
                                      ? const Icon(Icons.person,
                                      color: Colors.grey)
                                      : null,
                                ),

                                const SizedBox(width: 10),

                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(
                                        color: Colors.white,
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

                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedYear,
                                    dropdownColor: Colors.black87,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: _years
                                        .map(
                                          (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() =>
                                        _selectedYear = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// ===== TOTAL CARD =====
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 24),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Total Fee Balance',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${percentPaid.toStringAsFixed(1)}% Paid',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$currency ${balance.toStringAsFixed(2)} / ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
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

                  /// ===== BODY =====
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Fee Payment',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        // DUE CARD
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Due Amount',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight:
                                          FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$currency ${dueAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight:
                                          FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Due Date: $dueDate',
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  // === PAYMENT OPTIONS BOTTOM SHEET ===
                                  showModalBottomSheet(
                                    context: context,
                                    shape:
                                    const RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (_) {
                                      return Padding(
                                        padding:
                                        const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Choose Payment Method',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Payable amount: $currency ${dueAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight:
                                                FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // ==== UPI OPTION ====
                                            ListTile(
                                              leading: const Icon(
                                                Icons.account_balance,
                                                color: Colors.green,
                                              ),
                                              title:
                                              const Text('UPI'),
                                              subtitle: const Text(
                                                  'Google Pay, PhonePe, UPI ID'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .vertical(
                                                      top: Radius
                                                          .circular(
                                                          24),
                                                    ),
                                                  ),
                                                  builder: (_) {
                                                    return Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .all(16),
                                                      child: Column(
                                                        mainAxisSize:
                                                        MainAxisSize
                                                            .min,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          const Text(
                                                            'Pay via UPI',
                                                            style:
                                                            TextStyle(
                                                              fontSize:
                                                              18,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              12),
                                                          Text(
                                                            'Amount: $currency ${dueAmount.toStringAsFixed(2)}',
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          const Text(
                                                              'UPI ID'),
                                                          const SizedBox(
                                                              height:
                                                              6),
                                                          const TextField(
                                                            decoration:
                                                            InputDecoration(
                                                              hintText:
                                                              'example@upi',
                                                              border:
                                                              OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          SizedBox(
                                                            width: double
                                                                .infinity,
                                                            child:
                                                            ElevatedButton(
                                                              onPressed:
                                                                  () {
                                                                // TODO: actual UPI integration
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child:
                                                              const Text(
                                                                'Pay with UPI',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),

                                            // ==== CARD OPTION ====
                                            ListTile(
                                              leading: const Icon(
                                                Icons.credit_card,
                                                color: Colors.blue,
                                              ),
                                              title: const Text(
                                                  'Debit / Credit Card'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .vertical(
                                                      top: Radius
                                                          .circular(
                                                          24),
                                                    ),
                                                  ),
                                                  builder: (_) {
                                                    return Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .all(16),
                                                      child: Column(
                                                        mainAxisSize:
                                                        MainAxisSize
                                                            .min,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          const Text(
                                                            'Pay via Card',
                                                            style:
                                                            TextStyle(
                                                              fontSize:
                                                              18,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              12),
                                                          Text(
                                                            'Amount: $currency ${dueAmount.toStringAsFixed(2)}',
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          const Text(
                                                              'Card Number'),
                                                          const SizedBox(
                                                              height:
                                                              6),
                                                          const TextField(
                                                            keyboardType:
                                                            TextInputType
                                                                .number,
                                                            decoration:
                                                            InputDecoration(
                                                              border:
                                                              OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              12),
                                                          Row(
                                                            children: const [
                                                              Expanded(
                                                                child:
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text('Expiry'),
                                                                    SizedBox(height: 6),
                                                                    TextField(
                                                                      decoration:
                                                                      InputDecoration(
                                                                        hintText:
                                                                        'MM/YY',
                                                                        border:
                                                                        OutlineInputBorder(),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width:
                                                                  12),
                                                              Expanded(
                                                                child:
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text('CVV'),
                                                                    SizedBox(height: 6),
                                                                    TextField(
                                                                      obscureText:
                                                                      true,
                                                                      decoration:
                                                                      InputDecoration(
                                                                        border:
                                                                        OutlineInputBorder(),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          SizedBox(
                                                            width: double
                                                                .infinity,
                                                            child:
                                                            ElevatedButton(
                                                              onPressed:
                                                                  () {
                                                                // TODO: card gateway integration
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child:
                                                              const Text(
                                                                'Pay with Card',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),

                                            // ==== NET BANKING OPTION ====
                                            ListTile(
                                              leading: const Icon(
                                                Icons
                                                    .account_balance_wallet,
                                                color: Colors.orange,
                                              ),
                                              title: const Text(
                                                  'Net Banking'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .vertical(
                                                      top: Radius
                                                          .circular(
                                                          24),
                                                    ),
                                                  ),
                                                  builder: (_) {
                                                    return Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .all(16),
                                                      child: Column(
                                                        mainAxisSize:
                                                        MainAxisSize
                                                            .min,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                        children: [
                                                          const Text(
                                                            'Pay via Net Banking',
                                                            style:
                                                            TextStyle(
                                                              fontSize:
                                                              18,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              12),
                                                          Text(
                                                            'Amount: $currency ${dueAmount.toStringAsFixed(2)}',
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          const Text(
                                                              'Select Bank'),
                                                          const SizedBox(
                                                              height:
                                                              6),
                                                          const TextField(
                                                            decoration:
                                                            InputDecoration(
                                                              hintText:
                                                              'Bank name',
                                                              border:
                                                              OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              16),
                                                          SizedBox(
                                                            width: double
                                                                .infinity,
                                                            child:
                                                            ElevatedButton(
                                                              onPressed:
                                                                  () {
                                                                // TODO: net banking integration
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child:
                                                              const Text(
                                                                'Proceed to Bank',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),

                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  'Pay Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// ===== MORE OPTIONS + TRANSACTION HISTORY =====
                        const Text(
                          'More Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              // Transaction History row (screenshot style)
                              ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(
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
                                trailing:
                                const Icon(Icons.chevron_right),
                                onTap: () {
                                  // bottom‑sheet me full history
                                  showModalBottomSheet(
                                    context: context,
                                    shape:
                                    const RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (_) {
                                      return Padding(
                                        padding:
                                        const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            const Text(
                                              'Transaction History',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                FontWeight.w700,
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
                                                (item['date'] ??
                                                    '')
                                                    .toString();
                                                final double amount =
                                                (item['amount']
                                                is num)
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
                                                    style:
                                                    const TextStyle(
                                                      fontWeight:
                                                      FontWeight
                                                          .w700,
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
          );
        },
      ),
    );
  }
}
