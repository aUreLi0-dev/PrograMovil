import 'package:ulima_plus/models/seccion_model.dart';
import 'api_client.dart';

class SeccionService {
  final ApiClient _apiClient = ApiClient();

  Future<Seccion?> findSectionById(String sectionReference) async {
    try {
      final path = _sectionPath(sectionReference);
      final response = await _apiClient.getJson(path);
      final data = response['data'] as Map<String, dynamic>?;

      if (response['success'] == true && data != null) {
        return Seccion.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _sectionPath(String sectionReference) {
    final cleanReference = sectionReference.trim();
    final isNumericId = int.tryParse(cleanReference) != null;

    if (isNumericId) {
      return '/api/v1/descripcion-cursos/sections/$cleanReference';
    }

    return '/api/v1/descripcion-cursos/sections/by-code/'
        '${Uri.encodeComponent(cleanReference)}';
  }
}
