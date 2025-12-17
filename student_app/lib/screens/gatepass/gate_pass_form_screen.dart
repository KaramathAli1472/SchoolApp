import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GatePassFormScreen extends StatefulWidget {
  final String studentUid;
  final String studentName;
  final String classId;
  final String idNumber; // roll / GR

  const GatePassFormScreen({
    super.key,
    required this.studentUid,
    required this.studentName,
    required this.classId,
    required this.idNumber,
  });

  @override
  State<GatePassFormScreen> createState() => _GatePassFormScreenState();
}

class _GatePassFormScreenState extends State<GatePassFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _reasonController = TextEditingController();

  DateTime? _fromDateTime;
  DateTime? _toDateTime;

  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required bool isFrom,
  }) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isFrom) {
        _fromDateTime = dt;
      } else {
        _toDateTime = dt;
      }
    });
  }

  Future<void> _submitGatePass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromDateTime == null || _toDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select From and To date/time')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('gatePassRequests').add({
        'studentUid': widget.studentUid,
        'studentName': widget.studentName,
        'classId': widget.classId,
        'idNumber': widget.idNumber,
        'reason': _reasonController.text.trim(),
        'fromDateTime': _fromDateTime,
        'toDateTime': _toDateTime,
        'requestedBy': 'parent', // ya 'student', app design ke hisab se
        'status': 'pending',
        'approvalNotes': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }); // [web:146][web:331]

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gate pass request submitted')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Error submitting gate pass: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit gate pass')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF6079EA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gate Pass Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info
                  Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Name',
                    value: widget.studentName,
                  ),
                  _InfoRow(
                    label: 'Class',
                    value: widget.classId,
                  ),
                  _InfoRow(
                    label: 'ID / Roll No',
                    value: widget.idNumber,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  const SizedBox(height: 12),
                  const Text(
                    'Gate Pass Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter reason';
                      }
                      if (v.trim().length < 5) {
                        return 'Please write at least 5 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDateTime(isFrom: true),
                          child: Text(_formatDateTime(_fromDateTime)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDateTime(isFrom: false),
                          child: Text(_formatDateTime(_toDateTime)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitGatePass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        'Submit Gate Pass',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
