/// Admin profile — a single record on the backend (`GET|PUT /profile`).
/// [avatar] is a data URL ("data:image/jpeg;base64,...") because the backend
/// stores the image as base64 text rather than a file.
class Profile {
  final String? displayName;
  final String? avatar;
  final String? updatedAt;

  const Profile({
    required this.displayName,
    required this.avatar,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        displayName: j['displayName'] as String?,
        avatar: j['avatar'] as String?,
        updatedAt: j['updatedAt'] as String?,
      );
}
