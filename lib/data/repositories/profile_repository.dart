import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../remote/supabase_provider.dart';

/// `public.profiles` – one row per account, guarded by row level security.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  Future<UserProfile?> fetch(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle()
        .timeout(_timeout);
    return row == null ? null : UserProfile.fromJson(row);
  }

  Future<void> upsert(String userId, UserProfile profile) async {
    await _client
        .from('profiles')
        .upsert({'id': userId, ...profile.toJson()}).timeout(_timeout);
  }
}

/// `null` in demo mode.
final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : ProfileRepository(client);
});
