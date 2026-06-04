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
    return UserModel(
      code: json['code'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      careerId: json['career_id'] as int?,
      especialidades: (json['especialidades'] as List?)?.cast<int>() ?? <int>[],
      currentCycle: json['currentCycle'] as String? ?? '2026-1',
      setupComplete: json['setupComplete'] as bool? ?? false,
      courseProgress: CourseProgress.fromJson(
        json['courseProgress'] as Map<String, dynamic>?,
      ),
    );
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
