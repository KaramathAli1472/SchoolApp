import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../achievements/AchievementsScreen.dart';
import '../announcements/announcements_screen.dart';
import '../assignments/assignments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../class_diary/ClassDiary.dart';
import '../event/event_calendar_screen.dart';
import '../fees/fees_screen.dart';
import '../gallery/gallery_screen.dart';
import '../library/library_screen.dart';
import '../objective/objective_exam_screen.dart';
import '../ptm/ptm_feedback_screen.dart';
import '../timetable/timetable_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Student not found')),
          );
        }

        final data = snapshot.data!.data()!;

        // Firestore fields (students collection)
        final name = (data['name'] ?? '') as String;
        final classId = (data['classId'] ?? '') as String; // e.g. class_1
        final branch = (data['branch'] ?? '') as String; // city / branch
        final idNumber = (data['idNumber'] ?? '') as String; // roll / GR
        final photoUrl = (data['photoUrl'] ?? '') as String; // optional

        // yahi values Assignments / Fees / Attendance ke liye use honge
        final String studentIdForScreens =
            data['id']?.toString() ?? ''; // student doc ka custom id field
        final String classIdForScreens =
            data['classId']?.toString() ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),

          // LEFT DRAWER (scrollable)
          drawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: Drawer(
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Top header with student info
                    Container(
                      width: double.infinity,
                      color: Colors.indigoAccent,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 32)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  idNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Class: $classId',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    ListTile(
                      leading: const Icon(
                        Icons.home,
                        color: Color(0xFF2196F3),
                      ),
                      title: const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.event_available,
                        size: 26,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final studentId = studentIdForScreens;
                        final clsId = classIdForScreens;

                        if (studentId.isEmpty || clsId.isEmpty) {
                          debugPrint(
                              '❌ Missing studentId or classId in dashboard data: $data');
                          return;
                        }

                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              studentDocId: studentId,
                              classId: clsId,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.schedule,
                        size: 26,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Timetable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final clsId = classIdForScreens;
                        if (clsId.isEmpty) {
                          debugPrint(
                              '❌ Timetable: classId missing in student data: $data');
                          return;
                        }

                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimetableScreen(
                              classId: clsId,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Finance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        size: 26,
                        color: Colors.teal,
                      ),
                      title: const Text(
                        'Fee Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);

                        final studentId = studentIdForScreens;
                        if (studentId.isEmpty) {
                          debugPrint(
                            'Fee Details: student id missing in dashboard data: $data',
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeesScreen(
                              studentDocId: studentId,
                            ),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Communication',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.assignment,
                        size: 26,
                        color: Colors.teal,
                      ),
                      title: const Text(
                        'Assignments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final clsId = classIdForScreens;
                        final sid = studentIdForScreens;

                        debugPrint(
                          '📚 Assignments tap => classId: $clsId, studentId: $sid',
                        );

                        if (clsId.isEmpty || sid.isEmpty) {
                          debugPrint(
                            '❌ Assignments: classId or studentId missing in dashboard data: $data',
                          );
                          return;
                        }

                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentsScreen(
                              classId: clsId,
                              studentId: sid,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.assignment,
                        size: 26,
                        color: Colors.purple,
                      ),
                      title: const Text(
                        'Event Calendar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EventCalendarScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.photo_library,
                        size: 26,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Gallery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GalleryScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        size: 26,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        'Archivement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.book,
                        size: 26,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Class Dairy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassDiaryScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.announcement,
                        size: 26,
                        color: Colors.orange,
                      ),
                      title: const Text(
                        'Announcement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnnouncementsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.feedback,
                        size: 26,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'P T M Feedback Form',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final clsId = classIdForScreens;
                        final sid = studentIdForScreens;

                        if (clsId.isEmpty || sid.isEmpty) {
                          debugPrint(
                            '❌ PTM Feedback: classId or studentId missing in student data: $data',
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PTMFeedbackScreen(
                              classId: clsId,
                              studentId: sid,
                              meetingId: 'PTM-${DateTime.now().year}', // abhi simple id, baad me real PTM id rakh sakte ho
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.menu_book,
                        size: 26,
                        color: Colors.blueAccent,
                      ),
                      title: const Text(
                        'Library',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final clsId = classIdForScreens; // ya sirf classId bhi use kar sakte ho

                        if (clsId.isEmpty) {
                          debugPrint('❌ Library: classId missing in student data: $data');
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibraryScreen(
                              classId: clsId,
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Acedemic',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.assignment,
                        size: 26,
                        color: Colors.purple,
                      ),
                      title: const Text(
                        'Objective Exams',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        final clsId = classIdForScreens; // upar tumne already set kiya hai

                        if (clsId.isEmpty) {
                          debugPrint('❌ Objective Exams: classId missing in student data: $data');
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObjectiveExamListScreen(
                              classId: clsId,   // 👈 required named parameter yahan pass karo
                            ),
                          ),
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Concerns',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.report_problem,
                        size: 26,
                        color: Colors.deepOrange,
                      ),
                      title: const Text(
                        'Parent Concern Form',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Visitor Mgmt',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.qr_code,
                        size: 26,
                        color: Colors.deepOrange,
                      ),
                      title: const Text(
                        'Gate Pass',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.settings,
                        size: 26,
                        color: Colors.blueGrey,
                      ),
                      title: const Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        size: 26,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Logout
                      },
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Version : 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
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
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: const Text(
              'Student Dashboard',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.indigoAccent),
          ),

          body: Column(
            children: [
              const SizedBox(height: 32),

              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFF6079EA),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Finding\nOneself!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF6079EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.black,
                        )
                            : null,
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Class: $classId',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Branch: $branch',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID: $idNumber',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Colors.white,
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
  }
}
