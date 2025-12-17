import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../achievements/AchievementsScreen.dart';
import '../announcements/announcements_screen.dart';
import '../assignments/assignments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../class_diary/ClassDiary.dart';
import '../concern/parent_concern_form_screen.dart';
import '../event/event_calendar_screen.dart';
import '../fees/fees_screen.dart';
import '../gallery/gallery_screen.dart';
import '../gatepass/gate_pass_form_screen.dart';
import '../library/library_screen.dart';
import '../objective/objective_exam_screen.dart';
import '../ptm/ptm_feedback_screen.dart';
import '../settings/settings_screen.dart';
import '../timetable/timetable_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout, please try again')),
      );
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadStudent() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('🔑 Firebase UID: $uid');

    final query = await FirebaseFirestore.instance
        .collection('students')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      debugPrint('❌ No student for this uid');
      throw Exception('Student not found');
    }

    final doc = query.docs.first;
    debugPrint('✅ Student docId: ${doc.id}, data: ${doc.data()}');
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _loadStudent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Student not found')));
        }

        final docSnap = snapshot.data!;
        final data = docSnap.data()!;

        // ✅ FIXED: Proper variable extraction
        final String uid = FirebaseAuth.instance.currentUser!.uid;
        final String studentDocId = docSnap.id;  // ✅ "102" from Firestore doc ID
        final String name = (data['name'] ?? '') as String;
        final String classId = (data['classId'] ?? '') as String;
        final String branch = (data['branch'] ?? '') as String;
        final String idNumber = (data['idNumber'] ?? '') as String;
        final String photoUrl = (data['photoUrl'] ?? '') as String;

        debugPrint('✅ Dashboard LOADED: studentDocId="$studentDocId", classId="$classId", name="$name"');

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          drawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: Drawer(
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Drawer Header
                    Container(
                      width: double.infinity,
                      color: Colors.indigoAccent,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(idNumber, style: const TextStyle(fontSize: 16, color: Colors.white)),
                                Text('Class: $classId', style: const TextStyle(fontSize: 16, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Home
                    ListTile(
                      leading: const Icon(Icons.home, color: Color(0xFF91A0F6)),
                      title: const Text('Home', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
                      onTap: () => Navigator.pop(context),
                    ),

                    // ✅ FIXED Attendance
                    ListTile(
                      leading: const Icon(Icons.event_available, size: 26, color: Colors.red),
                      title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (studentDocId.isEmpty || classId.isEmpty) {
                          debugPrint('❌ Attendance: studentDocId="$studentDocId" | classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        debugPrint('➡️ Opening Attendance: studentDocId="$studentDocId", classId="$classId"');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(studentDocId: studentDocId, classId: classId),
                          ),
                        );
                      },
                    ),

                    // Timetable ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.schedule, size: 26, color: Colors.green),
                      title: const Text('Timetable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty) {
                          debugPrint('❌ Timetable: classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(classId: classId)));
                      },
                    ),

                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Finance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Fees ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.attach_money, size: 26, color: Colors.teal),
                      title: const Text('Fee Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (studentDocId.isEmpty) {
                          debugPrint('❌ Fees: studentDocId="$studentDocId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FeesScreen(studentDocId: studentDocId)));
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Communication', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Assignments ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.assignment, size: 26, color: Colors.teal),
                      title: const Text('Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty || studentDocId.isEmpty) {
                          debugPrint('❌ Assignments: classId="$classId" | studentDocId="$studentDocId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AssignmentsScreen(classId: classId, studentId: studentDocId)),
                        );
                      },
                    ),

                    // Event Calendar ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.assignment, size: 26, color: Colors.purple),
                      title: const Text('Event Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCalendarScreen()));
                      },
                    ),

                    // Gallery ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.photo_library, size: 26, color: Colors.green),
                      title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen()));
                      },
                    ),

                    // Achievement ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.emoji_events, size: 26, color: Colors.amber),
                      title: const Text('Achievement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                      },
                    ),

                    // Class Diary ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.book, size: 26, color: Colors.blue),
                      title: const Text('Class Diary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassDiaryScreen()));
                      },
                    ),

                    // Announcement ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.announcement, size: 26, color: Colors.orange),
                      title: const Text('Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
                      },
                    ),

                    // PTM Feedback ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.feedback, size: 26, color: Colors.green),
                      title: const Text('PTM Feedback Form', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty || studentDocId.isEmpty) {
                          debugPrint('❌ PTM: classId="$classId" | studentDocId="$studentDocId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PTMFeedbackScreen(
                              classId: classId,
                              studentId: studentDocId,
                              meetingId: 'PTM-${DateTime.now().year}',
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Library ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.menu_book, size: 26, color: Colors.blueAccent),
                      title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty) {
                          debugPrint('❌ Library: classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryScreen(classId: classId)));
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Academic', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Objective Exams ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.assignment, size: 26, color: Colors.purple),
                      title: const Text('Objective Exams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty) {
                          debugPrint('❌ Exams: classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ObjectiveExamListScreen(classId: classId)));
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Concerns', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Parent Concern ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.support_agent, size: 26, color: Colors.deepOrange),
                      title: const Text('Parent Concern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty) {
                          debugPrint('❌ Concern: classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentConcernFormScreen(
                              studentUid: uid,
                              studentName: name,
                              classId: classId,
                              idNumber: idNumber,
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Visitor Mgmt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Gate Pass ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.qr_code, size: 26, color: Colors.deepOrange),
                      title: const Text('Gate Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        if (classId.isEmpty) {
                          debugPrint('❌ Gate Pass: classId="$classId"');
                          return;
                        }
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GatePassFormScreen(
                              studentUid: uid,
                              studentName: name,
                              classId: classId,
                              idNumber: idNumber,
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),

                    // Settings ✅ FIXED
                    ListTile(
                      leading: const Icon(Icons.settings, size: 26, color: Colors.blueGrey),
                      title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              studentName: name,
                              classId: classId,
                              idNumber: idNumber,
                              branch: branch,
                            ),
                          ),
                        );
                      },
                    ),

                    // Logout
                    ListTile(
                      leading: const Icon(Icons.logout, size: 26, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () async {
                        Navigator.pop(context);
                        await _logout(context);
                      },
                    ),

                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Version : 1.0.0', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          appBar: AppBar(
            backgroundColor: const Color(0xFF6079EA),
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: const Text('Student Dashboard', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.indigoAccent),
          ),

          body: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(color: Color(0xFF6079EA), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 60, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Finding\nOneself!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF6079EA), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty ? const Icon(Icons.person, size: 32, color: Colors.black) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text('Class: $classId', style: const TextStyle(fontSize: 14, color: Colors.white)),
                            Text('Branch: $branch', style: const TextStyle(fontSize: 14, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text('ID: $idNumber', style: const TextStyle(fontSize: 13, color: Colors.white)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

