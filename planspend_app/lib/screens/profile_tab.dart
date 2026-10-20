import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const ProfileTab({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ฟังก์ชันเลือกรูปภาพโปรไฟล์จากคลังภาพ
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final updatedUser = UserModel(
        id: widget.user.id,
        name: widget.user.name,
        profileImagePath: image.path,
        monthlyIncome: widget.user.monthlyIncome,
      );

      await DBHelper.instance.updateUser(updatedUser);
      widget.onUserUpdated(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตรูปโปรไฟล์เรียบร้อยแล้ว')),
      );
    }
  }

  // Dialog สำหรับแก้ไขข้อมูลส่วนตัวและรายได้
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.user.name);
    final incomeController = TextEditingController(
      text: widget.user.monthlyIncome > 0 ? widget.user.monthlyIncome.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('แก้ไขข้อมูลโปรไฟล์การเงิน'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อผู้ใช้งาน',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: incomeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'รายได้ประจำเดือน (บาท)',
                    hintText: 'เช่น 25000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newIncome = double.tryParse(incomeController.text.trim()) ?? 0.0;

                if (newName.isNotEmpty) {
                  final updatedUser = UserModel(
                    id: widget.user.id,
                    name: newName,
                    profileImagePath: widget.user.profileImagePath,
                    monthlyIncome: newIncome,
                  );

                  await DBHelper.instance.updateUser(updatedUser);
                  widget.onUserUpdated(updatedUser);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัปเดตข้อมูลการเงินเรียบร้อยแล้ว')),
                  );
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันออกจากระบบ / สลับบัญชี
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double monthlyIncome = widget.user.monthlyIncome;
    final double avgDailyBudget = monthlyIncome > 0 ? monthlyIncome / 30 : 0.0;
    final bool hasPhoto = widget.user.profileImagePath != null && widget.user.profileImagePath!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('โปรไฟล์การเงินส่วนบุคคล'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. ส่วนรูปโปรไฟล์พร้อมปุ่มเปลี่ยนรูป
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: hasPhoto
                        ? (kIsWeb
                            ? NetworkImage(widget.user.profileImagePath!)
                            : FileImage(File(widget.user.profileImagePath!)) as ImageProvider)
                        : null,
                    child: !hasPhoto
                        ? const Icon(Icons.person, size: 65, color: Colors.deepPurple)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. ชื่อผู้ใช้และปุ่มแก้ไข
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 20),
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. การ์ดแสดงสรุปสถานะการเงิน
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.payments_outlined, color: Colors.deepPurple),
                    title: const Text('รายได้ประจำเดือน'),
                    trailing: Text(
                      '฿${monthlyIncome.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calculate_outlined, color: Colors.deepPurple),
                    title: const Text('งบประมาณเฉลี่ย/วัน (แนะนำ)'),
                    subtitle: const Text('คำนวณจากรายได้ ÷ 30 วัน', style: TextStyle(fontSize: 12)),
                    trailing: Text(
                      '฿${avgDailyBudget.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.savings_outlined, color: Colors.deepPurple),
                    title: const Text('สถานะบัญชี'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: #${widget.user.id ?? 1}',
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. ปุ่มจัดการข้อมูลและสลับบัญชี
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_note),
              label: const Text('แก้ไขข้อมูลส่วนตัว / ตั้งค่ารายได้'),
              onPressed: _showEditProfileDialog,
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ / สลับบัญชี'),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }
}