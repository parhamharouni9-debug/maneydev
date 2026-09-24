import 'json_parsing.dart';

class AppUser {
  final String id;
  final String email;
  final String name;

  AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: requiredText(j, 'id'),
        email: requiredText(j, 'email'),
        name: requiredText(j, 'name'),
      );
}
