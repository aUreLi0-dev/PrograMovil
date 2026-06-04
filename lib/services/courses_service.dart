import 'dart:convert';
import 'package:flutter/services.dart';

// servicio singleton que carga los cursos desde el json
class CoursesService {
  static final CoursesService _instance = CoursesService._internal();

  factory CoursesService() {
    return _instance;
  }

  CoursesService._internal();

  late List<Map<String, dynamic>> _coursesData;
  bool _isLoaded = false;

  // lee courses.json y lo guarda como lista de mapas
  Future<void> loadCoursesData() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/courses.json',
      );

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final cursosList = jsonData['cursos'] as List<dynamic>? ?? [];

      _coursesData = List<Map<String, dynamic>>.from(cursosList);

      _isLoaded = true;
      print('✓ Datos de cursos cargados: ${_coursesData.length} cursos');
    } catch (e) {
      print('✗ Error al cargar datos de cursos: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> get allCourses => _coursesData;

  // busca un curso por su id
  Map<String, dynamic>? getCourseById(String id) {
    try {
      return _coursesData.firstWhere((course) => course['id'] == id);
    } catch (e) {
      return null;
    }
  }

  bool get isLoaded => _isLoaded;
}
