import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ScheduleService {
  final ApiClient _apiClient = ApiClient();

  /// Obtiene la lista de secciones y horarios del estudiante desde el backend.
  /// Endpoint: GET /api/v1/students/{studentId}/schedule
  Future<List<Map<String, dynamic>>> fetchStudentSchedule(int studentId) async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/students/$studentId/schedule',
        authenticated: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final seccionesRaw = data['secciones'] as List<dynamic>? ?? [];
        return seccionesRaw
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error al obtener el horario del estudiante desde backend: $e');
      rethrow;
    }
    return [];
  }
}
