import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `null` in demo mode (no keys or Supabase failed to start). Overridden in
/// `main()` with the initialised client.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
