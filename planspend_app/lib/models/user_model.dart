class UserModel {
  final int? id;
  final String name;
  final String? profileImagePath;
  final double monthlyIncome;

  UserModel({
    this.id,
    required this.name,
    this.profileImagePath,
    required this.monthlyIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profile_image_path': profileImagePath,
      'monthly_income': monthlyIncome,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      profileImagePath: map['profile_image_path'],
      monthlyIncome: map['monthly_income']?.toDouble() ?? 0.0,
    );
  }
}