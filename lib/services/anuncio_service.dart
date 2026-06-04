import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../configs/generic_response.dart';
import '../models/anuncio_model.dart';
import 'section_representative_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

class AnuncioService {
  final UserService _userService = UserService();
  final SectionRepresentativeService _repService =
      SectionRepresentativeService();

  Future<GenericResponse<List<Anuncio>>> fetchAnuncios(String idSeccion) async {
    try {
      // 1. Cargar anuncios estáticos del JSON en assets
      final String response =
          await rootBundle.loadString('assets/data/anuncios.json');
      final data = json.decode(response);
      final List<dynamic> anunciosRaw = data['anuncios'] ?? [];

      final List<Anuncio> combined = [];

      for (final a in anunciosRaw) {
        final autorCode = a['autorCode'].toString();
        final user = await _userService.findUserByCode(autorCode);
        final role =
            await _repService.findHighestRoleByStudentCode(autorCode);

        combined.add(Anuncio.fromJson(
          a,
          autorName: user?.fullName ?? autorCode,
          autorRole: role,
        ));
      }

      // 2. Cargar anuncios locales guardados por el delegado
      final String? localRaw = StorageService.to.savedLocalAnuncios;
      if (localRaw != null) {
        final List<dynamic> localDecoded = json.decode(localRaw);
        final List<Anuncio> localAnuncios =
            localDecoded.map((x) => Anuncio.fromJson(x)).toList();
        combined.addAll(localAnuncios);
      }

      // 3. Filtrar por sección y ordenar por fecha/ID (los más nuevos primero)
      final filtrados =
          combined.where((a) => a.idSeccion == idSeccion).toList();
      
      // Ordenar por ID descendente de forma simple (o fecha) para mostrar los nuevos arriba
      filtrados.sort((a, b) => b.id.compareTo(a.id));

      return GenericResponse(
        success: true,
        data: filtrados,
        message: 'Anuncios cargados con éxito',
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
      final String? localRaw = StorageService.to.savedLocalAnuncios;
      List<dynamic> localDecoded = [];
      if (localRaw != null) {
        localDecoded = json.decode(localRaw);
      }

      localDecoded.add(nuevo.toJson());
      await StorageService.to.saveLocalAnuncios(json.encode(localDecoded));

      return GenericResponse(
        success: true,
        data: true,
        message: 'Anuncio guardado localmente con éxito',
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
