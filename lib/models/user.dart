class User {
  final String username;
  final String fullName;
  final String role;
  final String phone;
  bool isFirstLogin;
  List<int> assignedLessons;
  String? profileImagePath;

  User({
    required this.username,
    required this.fullName,
    required this.role,
    required this.phone,
    this.isFirstLogin = false,
    this.assignedLessons = const [],
    this.profileImagePath,
  });
}
