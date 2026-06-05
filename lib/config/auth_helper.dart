import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class AuthHelper {
  static AppUser? userFromAuth(User? authUser) {
    if (authUser == null) return null;
    final meta = authUser.userMetadata;
    if (meta == null) return null;
    return AppUser(
      username: meta['username'] as String? ?? authUser.email ?? '',
      fullName: meta['full_name'] as String? ?? authUser.email?.split('@').first ?? 'User',
      role: meta['role'] as String? ?? 'student',
      phone: meta['phone'] as String? ?? '',
      email: authUser.email ?? '',
      isFirstLogin: false,
      isSuperAdmin: meta['is_super_admin'] as bool? ?? false,
      isPrefect: meta['is_prefect'] as bool? ?? false,
      assignedLessons: (meta['assigned_lessons'] as List<dynamic>?)?.cast<int>() ?? [],
      profileImagePath: meta['profile_image_url'] as String?,
    );
  }

  static Map<String, dynamic> signUpMetadata({
    required String username,
    required String fullName,
    required String role,
    String phone = '',
    bool isSuperAdmin = false,
    bool isPrefect = false,
  }) {
    return {
      'username': username,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'is_super_admin': isSuperAdmin,
      'is_prefect': isPrefect,
    };
  }
}
