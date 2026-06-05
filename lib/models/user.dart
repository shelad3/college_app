class User {
  final String username;
  final String fullName;
  final String role;
  final String phone;
  final String email;
  bool isFirstLogin;
  List<int> assignedLessons;
  String? profileImagePath;
  final bool isSuperAdmin;
  final bool isPrefect;

  User({
    required this.username,
    required this.fullName,
    required this.role,
    required this.phone,
    this.email = '',
    this.isFirstLogin = false,
    this.assignedLessons = const [],
    this.profileImagePath,
    this.isSuperAdmin = false,
    this.isPrefect = false,
  });
}
