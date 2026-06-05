// lib/models/user_model.dart
// Modelo del alumno autenticado en la app.

import 'malla_models.dart';

class UserModel {
  final String code;
  final String firstName;
  final String lastName;
  int? careerId;
  List<int> especialidades;
  final String currentCycle;
  bool setupComplete;
  CourseProgress? courseProgress;

  UserModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    this.careerId,
    List<int>? especialidades,
    required this.currentCycle,
    required this.setupComplete,
    this.courseProgress,
  }) : especialidades = especialidades ?? <int>[];

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name']?.toString();
    final nameParts = (fullName ?? '').trim().split(RegExp(r'\s+'));
    final currentLevel = (json['current_level'] as num?)?.toInt();
    final courseProgressJson = json['courseProgress'] as Map<String, dynamic>?;

    return UserModel(
      code: json['code'] as String,
      firstName:
          json['firstName'] as String? ??
          (nameParts.isNotEmpty ? _extractFirstName(nameParts) : ''),
      lastName:
          json['lastName'] as String? ??
          (nameParts.length > 1 ? _extractLastName(nameParts) : ''),
      careerId: json['career_id'] as int?,
      especialidades: (json['especialidades'] as List?)?.cast<int>() ?? <int>[],
      currentCycle: json['currentCycle'] as String? ?? '2026-1',
      setupComplete:
          json['setupComplete'] as bool? ??
          json['specialty_setup_completed'] as bool? ??
          false,
      courseProgress: courseProgressJson != null
          ? CourseProgress.fromJson({
              ...courseProgressJson,
              'currentLevel': currentLevel,
            })
          : CourseProgress(
              currentLevel: currentLevel,
              approvedLevels: currentLevel == null
                  ? <int>{}
                  : List.generate(
                      currentLevel > 1 ? currentLevel - 1 : 0,
                      (index) => index + 1,
                    ).toSet(),
              approvedElectives: <String>{},
            ),
    );
  }

  static String _extractFirstName(List<String> parts) {
    if (parts.length <= 2) return parts.first;
    return parts.sublist(0, parts.length - 2).join(' ');
  }

  static String _extractLastName(List<String> parts) {
    if (parts.length == 2) return parts.last;
    return parts.sublist(parts.length - 2).join(' ');
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'firstName': firstName,
    'lastName': lastName,
    'career_id': careerId,
    'especialidades': especialidades,
    'currentCycle': currentCycle,
    'setupComplete': setupComplete,
  };
}
