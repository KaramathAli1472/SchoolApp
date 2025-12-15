import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'firebase_options.dart';
import 'config/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/student_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Screen ko on rakho (sleep na ho)
  await WakelockPlus.enable();

  runApp(const SchoolStudentApp());
}

class SchoolStudentApp extends StatelessWidget {
  const SchoolStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Student App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.dashboard: (context) => const StudentDashboardScreen(),
      },
    );
  }
}
