import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url =>
      dotenv.env['SUPABASE_URL'] ?? 'https://ceeduwdhbstnflixscxw.supabase.co';
  static String get publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? 'sb_publishable_tIGc13A21pPhYLXMntBqoQ_9mK4lqZP';
}

class UpdateConfig {
  static String get repoOwner =>
      dotenv.env['GITHUB_REPO_OWNER'] ?? 'shelad3';
  static String get repoName =>
      dotenv.env['GITHUB_REPO_NAME'] ?? 'college_app';
}
