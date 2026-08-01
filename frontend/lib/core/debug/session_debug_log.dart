import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String debugAccessTokenLabel(String? token) {
  if (token == null || token.isEmpty) {
    return '<none>';
  }

  if (token.length <= 24) {
    return token;
  }

  return '${token.substring(0, 12)}...${token.substring(token.length - 8)} '
      '(len=${token.length})';
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

  final auth = Supabase.instance.client.auth;
  final currentUser = auth.currentUser;
  final currentSession = auth.currentSession;
  final currentAccessToken = currentSession?.accessToken;

  final parts = <String>[
    '[TEMP AUTH DEBUG] $label',
    'currentUser.email=${currentUser?.email ?? '<null>'}',
    'currentUser.id=${currentUser?.id ?? '<null>'}',
    'currentSession.user.id=${currentSession?.user.id ?? '<null>'}',
    'accessToken=${debugAccessTokenLabel(currentAccessToken)}',
  ];

  if (responseUser != null || responseSession != null) {
    parts.add('responseUser.email=${responseUser?.email ?? '<null>'}');
    parts.add('responseUser.id=${responseUser?.id ?? '<null>'}');
    parts
        .add('responseSession.user.id=${responseSession?.user.id ?? '<null>'}');
    parts.add(
      'responseAccessToken=${debugAccessTokenLabel(responseSession?.accessToken)}',
    );
  }

  for (final entry in extra.entries) {
    parts.add('${entry.key}=${entry.value ?? '<null>'}');
  }

  debugPrint(parts.join(' | '));
}
