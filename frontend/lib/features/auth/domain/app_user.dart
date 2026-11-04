class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
  });
  final int id;
  final String username, name, email, role;
  final bool isAdmin;
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    username: json['username'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String,
    role: json['role'] as String,
    isAdmin: json['is_staff'] == true,
  );
}
