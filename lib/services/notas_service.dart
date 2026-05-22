import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y cargar notas localmente por estudiante
class NotasService {
  static final NotasService _instance = NotasService._internal();
  static const String _notasKey = 'notas_estudiante';

  factory NotasService() {
    return _instance;
  }

  NotasService._internal();

  /// Guarda las notas del alumno actual en memoria local
  Future<void> guardarNotas(String idEstudiante, List<Map<String, dynamic>> cursos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir los cursos a formato serializable (RxList a List)
      final cursosSerializables = cursos.map((curso) {
        return {
          'id': curso['id'],
          'nombre': curso['nombre'],
          'ciclo': curso['ciclo'],
          'idSeccion': curso['idSeccion'],
          'notas': (curso['notas'] as List).toList(),
        };
      }).toList();

      final jsonString = jsonEncode(cursosSerializables);
      await prefs.setString('${_notasKey}_$idEstudiante', jsonString);
      print('✓ Notas guardadas para estudiante: $idEstudiante');
    } catch (e) {
      print('✗ Error al guardar notas: $e');
    }
  }

  /// Carga las notas del alumno actual desde memoria local
  Future<List<Map<String, dynamic>>> cargarNotas(String idEstudiante) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('${_notasKey}_$idEstudiante');
      
      if (jsonString == null) {
        print('ℹ️ No hay notas guardadas para: $idEstudiante');
        return [];
      }

      final List<dynamic> cursosJson = jsonDecode(jsonString);
      return List<Map<String, dynamic>>.from(cursosJson);
    } catch (e) {
      print('✗ Error al cargar notas: $e');
      return [];
    }
  }

  /// Elimina las notas del alumno
  Future<void> eliminarNotas(String idEstudiante) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_notasKey}_$idEstudiante');
      print('✓ Notas eliminadas para: $idEstudiante');
    } catch (e) {
      print('✗ Error al eliminar notas: $e');
    }
  }

  /// Obtiene el ID del estudiante actual desde SharedPreferences
  Future<String?> obtenerIdEstudianteActual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('currentStudentId');
    } catch (e) {
      print('✗ Error al obtener ID del estudiante: $e');
      return null;
    }
  }

  /// Guarda el ID del estudiante actual
  Future<void> guardarIdEstudianteActual(String idEstudiante) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentStudentId', idEstudiante);
    } catch (e) {
      print('✗ Error al guardar ID del estudiante: $e');
    }
  }
}
