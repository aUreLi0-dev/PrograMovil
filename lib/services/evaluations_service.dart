import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course_syllabus_model.dart';

// servicio singleton que carga el silabo (evaluaciones) desde el json
class EvaluationSyllabusService {
  static final EvaluationSyllabusService _instance =
      EvaluationSyllabusService._internal();

  factory EvaluationSyllabusService() {
    return _instance;
  }

  EvaluationSyllabusService._internal();

  late List<CourseSyllabus> _syllabusData;
  bool _isLoaded = false;

  // lee evaluaciones.json y lo convierte en lista de cursos con sus evaluaciones
  Future<void> loadEvaluationData() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/evaluaciones.json',
      );

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final cursosList = jsonData['cursos'] as List<dynamic>? ?? [];

      _syllabusData = cursosList
          .map((curso) => CourseSyllabus.fromJson(curso as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
      print('✓ Datos de evaluaciones cargados: ${_syllabusData.length} cursos');
    } catch (e) {
      print('✗ Error al cargar datos de evaluaciones: $e');
      rethrow;
    }
  }

  List<CourseSyllabus> get allSyllabuses => _syllabusData;
}
