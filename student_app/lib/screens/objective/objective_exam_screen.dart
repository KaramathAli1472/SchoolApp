// lib/screens/objective/objective_exam_screen.dart

import 'package:flutter/material.dart';

class ObjectiveExamScreen extends StatefulWidget {
  const ObjectiveExamScreen({super.key});

  @override
  State<ObjectiveExamScreen> createState() => _ObjectiveExamScreenState();
}

class _ObjectiveExamScreenState extends State<ObjectiveExamScreen> {
  // Abhi dummy questions; baad me Firestore se laa sakte ho
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the capital of India?',
      'options': ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'],
      'answerIndex': 1,
    },
    {
      'question': '2 + 2 = ?',
      'options': ['3', '4', '5', '6'],
      'answerIndex': 1,
    },
    {
      'question': 'Flutter uses which language?',
      'options': ['Java', 'Swift', 'Dart', 'Kotlin'],
      'answerIndex': 2,
    },
  ];

  int _currentIndex = 0;
  int? _selectedOption; // 0–3
  int _score = 0;
  bool _submitted = false;

  void _onOptionSelected(int index) {
    setState(() {
      _selectedOption = index;
    });
  }

  void _onNextOrSubmit() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }

    final currentQ = _questions[_currentIndex];
    if (_selectedOption == currentQ['answerIndex']) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    } else {
      setState(() {
        _submitted = true;
      });
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final total = _questions.length;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Exam Completed'),
          content: Text('Your score: $_score / $total'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _score = 0;
                  _currentIndex = 0;
                  _selectedOption = null;
                  _submitted = false;
                });
              },
              child: const Text('Retake'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final options = currentQ['options'] as List<String>;
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objective Exam'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Question count
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // Question text
            Text(
              currentQ['question'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedOption == index;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedOption,
                      onChanged: _submitted
                          ? null
                          : (val) {
                        if (val != null) _onOptionSelected(val);
                      },
                      title: Text(options[index]),
                      activeColor: Colors.deepPurple,
                      selected: isSelected,
                    ),
                  );
                },
              ),
            ),

            // Next / Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitted ? null : _onNextOrSubmit,
                child: Text(isLast ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
