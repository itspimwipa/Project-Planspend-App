import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'calendar_tab.dart';
import 'profile_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel user;
  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _updateUser(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      CalendarTab(user: _currentUser),
      ProfileTab(user: _currentUser, onUserUpdated: _updateUser),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'ตารางค่าใช้จ่าย',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}