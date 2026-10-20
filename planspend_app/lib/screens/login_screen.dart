import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  List<UserModel> _savedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await DBHelper.instance.getAllUsers();
      setState(() {
        _savedUsers = users;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _loginWithUser(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(user: user),
      ),
    );
  }

  void _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('กรุณากรอกชื่อผู้ใช้งาน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DBHelper.instance.loginOrRegisterUser(name);
      if (!mounted) return;
      _loginWithUser(user);
    } catch (e) {
      _showMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteUser(int id) async {
    await DBHelper.instance.deleteUser(id);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ / เริ่มใช้งาน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 70,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PlanSpend',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Text(
                        'แอปวางแผนและติดตามค่าใช้จ่าย',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // ส่วนที่ 1: รายการบัญชีเดิมที่เคยสร้างไว้ในฐานข้อมูล
                      if (_savedUsers.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'เลือกบัญชีเดิมเข้าใช้งาน:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _savedUsers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = _savedUsers[index];
                              final bool hasPhoto = user.profileImagePath != null &&
                                  user.profileImagePath!.isNotEmpty;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade600,
                                  foregroundColor: Colors.white,
                                  backgroundImage: hasPhoto
                                      ? (kIsWeb
                                          ? NetworkImage(user.profileImagePath!)
                                          : FileImage(File(user.profileImagePath!))
                                              as ImageProvider)
                                      : null,
                                  child: !hasPhoto
                                      ? Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'รายได้: ฿${user.monthlyIncome.toStringAsFixed(0)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    if (user.id != null) {
                                      _deleteUser(user.id!);
                                    }
                                  },
                                ),
                                onTap: () => _loginWithUser(user),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'หรือสร้างบัญชีใหม่',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ส่วนที่ 2: ช่องกรอกสร้างบัญชีใหม่
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อผู้ใช้งาน / บัญชีใหม่',
                          hintText: 'เช่น fah55, Somchai',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.deepPurple,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'เข้าสู่ระบบ / สร้างบัญชีใหม่',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}