import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String debugAccessTokenLabel(String? token) {
  return token == null || token.isEmpty ? '<none>' : '<redacted>';
}

void logSupabaseSessionSnapshot(
  String label, {
  User? responseUser,
  Session? responseSession,
  Map<String, Object?> extra = const {},
}) {
  if (!kDebugMode) {
    return;
  }

  debugPrint('[Auth] $label');
}
