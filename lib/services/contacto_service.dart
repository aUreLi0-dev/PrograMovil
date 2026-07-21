import 'package:flutter/foundation.dart';

import '../models/contacto_model.dart';
import '../models/docente_model.dart';
import 'api_client.dart';

class ContactoService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> fetchContactos(String idSeccion) async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/descripcion-cursos/sections/$idSeccion/contacts',
      );
      final data = response['data'] as Map<String, dynamic>?;
      final docenteJson = data?['docente'] as Map<String, dynamic>?;
      final alumnosRaw = (data?['alumnos'] as List?) ?? const [];

      return {
        'docente': docenteJson != null ? Docente.fromJson(docenteJson) : null,
        'alumnos': alumnosRaw
            .whereType<Map>()
            .map(
              (item) => ContactoCurso.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      };
    } catch (e) {
      debugPrint('Error cargando contactos: $e');
      return {'docente': null, 'alumnos': <ContactoCurso>[]};
    }
  }
}
