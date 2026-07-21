// lib/models/malla_models.dart
// Modelos simples para pintar la malla que ya viene calculada desde backend.

import 'package:flutter/material.dart';

enum CourseStatus { locked, unlocked, current, approved }

CourseStatus courseStatusFromJson(Object? raw) {
  switch (raw?.toString()) {
    case 'approved':
    case 'simulated_approved':
      return CourseStatus.approved;
    case 'current':
    case 'in_progress':
    case 'simulated_in_progress':
      return CourseStatus.current;
    case 'unlocked':
    case 'available':
    case 'simulated_unlocked':
      return CourseStatus.unlocked;
    case 'simulated_locked':
    case 'locked':
    default:
      return CourseStatus.locked;
  }
}

String courseStatusToApiValue(CourseStatus status) {
  switch (status) {
    case CourseStatus.approved:
      return 'approved';
    case CourseStatus.current:
      return 'current';
    case CourseStatus.unlocked:
      return 'available';
    case CourseStatus.locked:
      return 'locked';
  }
}

extension CourseStatusX on CourseStatus {
  String get label {
    switch (this) {
      case CourseStatus.locked:
        return 'Bloqueado';
      case CourseStatus.unlocked:
        return 'Disponible';
      case CourseStatus.current:
        return 'Cursando';
      case CourseStatus.approved:
        return 'Aprobado';
    }
  }

  Color get color {
    switch (this) {
      case CourseStatus.approved:
        return const Color(0xFF10B981);
      case CourseStatus.current:
        return const Color(0xFFF59E0B);
      case CourseStatus.unlocked:
        return const Color(0xFF0EA5E9);
      case CourseStatus.locked:
        return const Color(0xFF94A3B8);
    }
  }

  Color get borderColor {
    switch (this) {
      case CourseStatus.approved:
        return const Color(0xFF059669);
      case CourseStatus.current:
        return const Color(0xFFD97706);
      case CourseStatus.unlocked:
        return const Color(0xFF0284C7);
      case CourseStatus.locked:
        return const Color(0xFF64748B);
    }
  }
}

enum CourseCategory { eegg, faculty, common, elective }

CourseCategory _parseCategory(String? raw) {
  switch (raw) {
    case 'EEGG':
    case 'general_studies':
      return CourseCategory.eegg;
    case 'COMMON':
    case 'common':
      return CourseCategory.common;
    case 'ELECTIVE':
    case 'elective':
      return CourseCategory.elective;
    case 'FACULTY':
    case 'faculty':
    default:
      return CourseCategory.faculty;
  }
}

class CourseNode {
  CourseNode({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.level,
    required this.prerequisites,
    required this.category,
    required this.row,
    required this.specialties,
    required this.status,
    this.requiredCompletedLevel,
    this.externalFaculty,
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final int level;
  final List<String> prerequisites;
  final CourseCategory category;
  final int row;
  final List<String> specialties;
  final CourseStatus status;
  final int? requiredCompletedLevel;
  final String? externalFaculty;

  bool get isElective => category == CourseCategory.elective;
  bool get isExternal => externalFaculty != null;

  List<String> get coursePrerequisites =>
      prerequisites.where((item) => !_isCycleMarker(item)).toList();

  bool _isCycleMarker(String value) =>
      value.startsWith('_') && value.endsWith('_CICLO_');

  factory CourseNode.fromApiJson(Map<String, dynamic> json) {
    return CourseNode(
      id: (json['curriculumCourseId'] ?? json['id']).toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin curso',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      prerequisites: _readStringList(json['prerequisites']),
      category: _parseCategory(json['category']?.toString()),
      row: (json['row'] as num?)?.toInt() ?? 0,
      specialties: _readStringList(json['specialties']),
      status: courseStatusFromJson(json['status']),
      requiredCompletedLevel: (json['requiredCompletedLevel'] as num?)?.toInt(),
      externalFaculty: json['externalFaculty']?.toString(),
    );
  }

  static List<String> _readStringList(Object? raw) {
    return ((raw as List?) ?? const []).map((item) => item.toString()).toList();
  }
}

class CourseProgress {
  CourseProgress({
    this.currentLevel,
    required this.approvedLevels,
    required this.approvedElectives,
  });

  final int? currentLevel;
  final Set<int> approvedLevels;
  final Set<String> approvedElectives;

  factory CourseProgress.empty() =>
      CourseProgress(approvedLevels: <int>{}, approvedElectives: <String>{});

  factory CourseProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CourseProgress.empty();
    final rawCurrentLevel = json['currentLevel'] ?? json['current_level'];

    return CourseProgress(
      currentLevel: rawCurrentLevel is num ? rawCurrentLevel.toInt() : null,
      approvedLevels: ((json['approvedLevels'] as List?) ?? const [])
          .map<int>((item) => (item as num).toInt())
          .toSet(),
      approvedElectives: ((json['approvedElectives'] as List?) ?? const [])
          .map((item) => item.toString())
          .toSet(),
    );
  }
}
