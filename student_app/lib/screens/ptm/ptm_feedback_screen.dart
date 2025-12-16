import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PTMFeedbackScreen extends StatefulWidget {
  final String? meetingId;
  final String? classId;
  final String? studentId;

  const PTMFeedbackScreen({
    Key? key,
    this.meetingId,
    this.classId,
    this.studentId,
  }) : super(key: key);

  @override
  State<PTMFeedbackScreen> createState() => _PTMFeedbackScreenState();
}

class _PTMFeedbackScreenState extends State<PTMFeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _meetingCtrl = TextEditingController();
  String? _selectedClassId;
  bool _submitting = false;

  final List<String> _classOptions = const [
    'class_1',
    'class_2',
    'class_3',
    'class_4',
    'class_5',
    'class_6',
    'class_7',
    'class_8',
    'class_9',
    'class_10',
  ];

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    _meetingCtrl.text = widget.meetingId ?? '';
  }

  Future<void> _submitFeedback() async {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class')),
      );
      return;
    }
    if (_meetingCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter meeting name / ID')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rating')),
      );
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short comment')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('ptmFeedback')
          .add({
        'meetingId': _meetingCtrl.text.trim(),
        'classId': _selectedClassId,
        'studentId': widget.studentId ?? 'unknown',
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }); // [web:331]

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error submitting PTM feedback: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _meetingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('PTM Feedback'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Keyboard open hone par bhi neeche tak scroll ho sake
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How was your Parent-Teacher Meeting?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Class select
                      Text(
                        'Select Class',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassId,
                            hint: const Text('Choose class'),
                            items: _classOptions
                                .map(
                                  (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClassId = val;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Meeting text field
                      Text(
                        'Meeting name / ID',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _meetingCtrl,
                        decoration: const InputDecoration(
                          hintText:
                          'Example: PTM Jan 2025, PTM-2025-01-20',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Rating
                      Text(
                        'Rating (1–5 stars)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          final value = index + 1;
                          final selected = _rating >= value;
                          return IconButton(
                            iconSize: 30,
                            icon: Icon(
                              Icons.star,
                              color: selected
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = value;
                              });
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // Comment
                      Text(
                        'Write your feedback',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText:
                          'Example: PTM was helpful, teacher explained progress clearly...',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Button bottom pe rahe, lekin scrollable bhi ho
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                            _submitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              textStyle:
                              const TextStyle(fontSize: 16),
                            ),
                            child: _submitting
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Submit Feedback'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
