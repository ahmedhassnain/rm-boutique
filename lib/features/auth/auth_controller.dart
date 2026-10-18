import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../shared/models/profile.dart';

/// Who is signed in and what role they have. The router listens to this
/// and sends each person to their own area (/admin, /customer, /rider).
class AuthController extends ChangeNotifier {
  AuthController() {
    _sub = supabase.auth.onAuthStateChange.listen((data) => _load(data.session));
    _load(supabase.auth.currentSession);
  }

  late final StreamSubscription<AuthState> _sub;

  bool _loading = true;
  Profile? _profile;

  /// True until we know whether someone is signed in.
  bool get loading => _loading;
  Profile? get profile => _profile;
  bool get isSignedIn => _profile != null;

  Future<void> _load(Session? session) async {
    if (session == null) {
      _profile = null;
    } else if (_profile?.id != session.user.id) {
      try {
        final row = await supabase.from('profiles').select().eq('id', session.user.id).single();
        _profile = Profile.fromJson(row);
      } catch (_) {
        _profile = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  /// Throws AuthException with a readable message on a wrong password.
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// New accounts are always customers. (Turn OFF "Confirm email" in the
  /// Supabase dashboard so sign-up logs in straight away for the demo.)
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'phone': phone?.trim()},
    );
  }

  Future<void> signOut() => supabase.auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
