class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
    this.bio = '',
    this.profileImage,
    this.profileImageUrl = '',
  });

  final int id;
  final String username, name, email, role;
  final bool isAdmin;
  final String bio;
  final String? profileImage;
  final String profileImageUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    username: json['username'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String,
    role: json['role'] as String,
    isAdmin: json['is_staff'] == true,
    bio: json['bio'] as String? ?? '',
    profileImage: json['profile_image'] as String?,
    profileImageUrl: json['profile_image_url'] as String? ?? '',
  );
}
