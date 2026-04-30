import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { aluno, staff, admin }

extension AppRoleX on AppRole {
  bool get canManageClasses => this == AppRole.admin;

  bool get canManageActivities => this == AppRole.admin;

  bool get canManageCalendar => this == AppRole.admin;

  bool get canEditRooms => this == AppRole.admin || this == AppRole.staff;

  String get label {
    return switch (this) {
      AppRole.admin => 'Administrador',
      AppRole.staff => 'Staff',
      AppRole.aluno => 'Aluno',
    };
  }
}

class SessionService {
  SessionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppRole> currentRole() async {
    final email = currentUser?.email;
    if (email == null) {
      return AppRole.aluno;
    }

    try {
      final row = await _client
          .from('usuarios_roles')
          .select('role')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      final role = row?['role'] as String?;
      return switch (role) {
        'admin' => AppRole.admin,
        'staff' => AppRole.staff,
        _ => AppRole.aluno,
      };
    } catch (_) {
      return AppRole.aluno;
    }
  }
}
