// lib/models/user_model.dart
// Modelo del alumno autenticado en la app.

import 'malla_models.dart';

class UserModel {
  final int? id;
  final String code;
  final String firstName;
  final String lastName;
  final String? email;
  int? careerId;
  String? careerName;
  List<int> especialidades;
  final String currentCycle;
  bool setupComplete;
  CourseProgress? courseProgress;

  UserModel({
    this.id,
    required this.code,
    required this.firstName,
    required this.lastName,
    this.email,
    this.careerId,
    this.careerName,
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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()),
      code: json['code'] as String,
      firstName:
          json['firstName'] as String? ??
          (nameParts.isNotEmpty ? _extractFirstName(nameParts) : ''),
      lastName:
          json['lastName'] as String? ??
          (nameParts.length > 1 ? _extractLastName(nameParts) : ''),
      email: json['institutional_email'] as String? ?? json['email'] as String?,
      careerId: json['career_id'] as int?,
      careerName: json['career'] is Map ? (json['career'] as Map)['name'] as String? : null,
      especialidades: _parseEspecialidades(json['especialidades']),
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

  static List<int> _parseEspecialidades(dynamic raw) {
    if (raw == null) return <int>[];
    if (raw is List) {
      if (raw.every((e) => e is int)) return raw.cast<int>();
      return raw.map((e) {
        if (e is int) return e;
        if (e is Map) return (e['id'] as num?)?.toInt() ?? 0;
        return int.tryParse(e.toString()) ?? 0;
      }).where((id) => id > 0).toList();
    }
    return <int>[];
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
