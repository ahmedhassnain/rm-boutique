/// The three roles. Same values as the `user_role` type in supabase/schema.sql.
enum UserRole {
  admin,
  customer,
  rider;

  static UserRole fromDb(String value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => throw ArgumentError('Unknown role: $value'),
      );

  /// Each role has its own area of the app: /admin, /customer, /rider.
  String get homePath => '/$name';
}

class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.email,
    this.fullName = '',
    this.phone,
  });

  final String id;
  final UserRole role;
  final String? email;
  final String fullName;
  final String? phone;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        role: UserRole.fromDb(json['role'] as String),
        email: json['email'] as String?,
        fullName: (json['full_name'] as String?) ?? '',
        phone: json['phone'] as String?,
      );
}
