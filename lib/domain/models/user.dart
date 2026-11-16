/// The signed-in person. [name] stays empty until onboarding asks for it.
class User {
  const User({required this.id, required this.email, this.name = '', this.color = 0xFFAF5C3C});

  final String id;
  final String email;
  final String name;

  /// Avatar background as ARGB. People pick a color, never a photo.
  final int color;

  User copyWith({String? name, int? color}) =>
      User(id: id, email: email, name: name ?? this.name, color: color ?? this.color);
}
