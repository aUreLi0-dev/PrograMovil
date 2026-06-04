import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/enrollment_model.dart';

// servicio singleton que carga las matriculas desde el json
class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();

  factory EnrollmentService() => _instance;

  EnrollmentService._internal();

  List<Enrollment>? _cachedEnrollments;

  // carga el json completo y lo cachea
  Future<List<Enrollment>> fetchEnrollments() async {
    if (_cachedEnrollments != null) return _cachedEnrollments!;
    try {
      final String response =
          await rootBundle.loadString('assets/data/enrollments.json');
      final data = json.decode(response);
      final List<dynamic> raw = data['enrollments'] ?? [];
      _cachedEnrollments =
          raw.map((e) => Enrollment.fromJson(e)).toList();
      return _cachedEnrollments!;
    } catch (e) {
      debugPrint('Error cargando enrollments: $e');
      return [];
    }
  }

  // filtra por seccion
  Future<List<Enrollment>> fetchBySection(String idSeccion) async {
    final enrollments = await fetchEnrollments();
    return enrollments.where((e) => e.idSeccion == idSeccion).toList();
  }

  // busca una matricula por su id
  Future<Enrollment?> findById(String id) async {
    final enrollments = await fetchEnrollments();
    try {
      return enrollments.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // filtra por codigo de alumno (el que usa el controller)
  Future<List<Enrollment>> fetchByStudentCode(String studentCode) async {
    final enrollments = await fetchEnrollments();
    return enrollments
        .where((e) => e.studentCode == studentCode)
        .toList();
  }
}
