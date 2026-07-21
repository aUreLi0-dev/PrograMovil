import 'package:flutter/foundation.dart';

import '../models/asesoria_model.dart';
import 'api_client.dart';

class AsesoriaService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Asesoria>> fetchAsesorias(String idSeccion) async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/descripcion-cursos/sections/$idSeccion/advising',
      );
      final data = (response['data'] as List?) ?? const [];
      return data
          .map((item) => Asesoria.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error cargando asesorias: $e');
      return [];
    }
  }
}
