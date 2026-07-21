import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'api_client.dart';

class SeccionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Seccion>> fetchSecciones() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/secciones.json',
      );
      final data = json.decode(response);

      final List<dynamic> sectionsRaw = data['secciones'] ?? [];

      return sectionsRaw
          .map((s) => Seccion.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error cargando secciones: $e');
      return [];
    }
  }

  Future<Seccion?> findSectionById(String id) async {
    try {
      final trimmedId = id.trim();
      final isNumeric = int.tryParse(trimmedId) != null;
      final path = isNumeric
          ? '/api/v1/descripcion-cursos/sections/$trimmedId'
          : '/api/v1/descripcion-cursos/sections/by-code/${Uri.encodeComponent(trimmedId)}';
      final response = await _apiClient.getJson(path);
      final data = response['data'] as Map<String, dynamic>?;
      if (response['success'] == true && data != null) {
        return Seccion.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('No existe seccion con id $id');
      return null;
    }
  }
}
