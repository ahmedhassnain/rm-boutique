import 'package:supabase_flutter/supabase_flutter.dart';

/// The one Supabase client. Initialised in main.dart.
/// Screens and view-models should NOT use this directly: go through the
/// repositories in lib/shared/repositories.
SupabaseClient get supabase => Supabase.instance.client;
