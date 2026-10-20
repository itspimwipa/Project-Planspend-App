import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  // บังคับให้ Flutter Binding พร้อมทำงานก่อนเรียกใช้ Database
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlanSpend App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // กำหนดหน้าแรกเป็น LoginScreen
      home: const LoginScreen(),
    );
  }
}