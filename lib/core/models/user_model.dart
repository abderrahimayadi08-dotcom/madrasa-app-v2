class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        role: map['role'] as String,
      );

  bool get isFinanceManager => role == 'finance_manager';
  bool get isMaintenanceManager => role == 'maintenance_manager';
  bool get isGeneralManager => role == 'general_manager';
  bool get isManager => isFinanceManager || isMaintenanceManager || isGeneralManager;
  bool get isMember => role == 'member';
}
