import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../configs/generic_response.dart';
import '../models/anuncio_model.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AnuncioService {
  final ApiClient _apiClient = ApiClient();

  Future<GenericResponse<List<Anuncio>>> fetchAnuncios(String idSeccion) async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/sections/$idSeccion/announcements',
      );
      final data = (response['data'] as List?) ?? const [];
      final anuncios = data
          .map((item) => Anuncio.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return GenericResponse(
        success: true,
        data: anuncios,
        message: response['message']?.toString() ?? 'Anuncios cargados',
      );
    } catch (e, stack) {
      debugPrint('Error cargando anuncios: $e');
      return GenericResponse(
        success: false,
        data: [],
        message: 'Error al cargar los anuncios',
        error: stack.toString(),
      );
    }
  }

  Future<GenericResponse<bool>> addAnuncio(Anuncio nuevo) async {
    try {
      final localRaw = StorageService.to.savedLocalAnuncios;
      var localDecoded = <dynamic>[];
      if (localRaw != null) {
        localDecoded = json.decode(localRaw) as List<dynamic>;
      }

      localDecoded.add(nuevo.toJson());
      await StorageService.to.saveLocalAnuncios(json.encode(localDecoded));

      return GenericResponse(
        success: true,
        data: true,
        message: 'Anuncio guardado localmente con exito',
      );
    } catch (e, stack) {
      debugPrint('Error guardando anuncio: $e');
      return GenericResponse(
        success: false,
        data: false,
        message: 'Error al guardar el anuncio',
        error: stack.toString(),
      );
    }
  }
}
