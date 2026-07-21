import 'package:ulima_plus/models/user_model.dart';

class ContactoCurso {
  final UserModel user;
  final String roleInSection;

  ContactoCurso({required this.user, required this.roleInSection});

  factory ContactoCurso.fromJson(Map<String, dynamic> json) {
    return ContactoCurso(
      user: UserModel.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      roleInSection: json['roleInSection']?.toString() ?? 'estudiante',
    );
  }
}
