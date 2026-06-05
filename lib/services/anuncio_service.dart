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
      // 1. Cargar anuncios estáticos desde el archivo JSON de assets
      final String response =
          await rootBundle.loadString('assets/data/anuncios.json');
      final data = json.decode(response); // Deserializar texto JSON a mapa de Dart
      final List<dynamic> anunciosRaw = data['anuncios'] ?? [];

      final List<Anuncio> combined = [];

      // Cruzar la información del autor para obtener su nombre real y rol
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

      // 2. Cargar anuncios locales (nuevos) creados por el delegado y guardados en memoria del teléfono
      final String? localRaw = StorageService.to.savedLocalAnuncios;
      if (localRaw != null) {
        final List<dynamic> localDecoded = json.decode(localRaw);
        final List<Anuncio> localAnuncios =
            localDecoded.map((x) => Anuncio.fromJson(x)).toList();
        combined.addAll(localAnuncios); // Combinar los anuncios estáticos y los creados en el celular
      }

      // 3. Filtrar los anuncios para mostrar solo los de la sección actual
      final filtrados =
          combined.where((a) => a.idSeccion == idSeccion).toList();
      
      // 4. Ordenar los anuncios por fecha descendente (los más recientes arriba)
      filtrados.sort((a, b) => _parseFecha(b.fecha).compareTo(_parseFecha(a.fecha)));

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
      // 1. Leer los anuncios guardados localmente como texto String
      final String? localRaw = StorageService.to.savedLocalAnuncios;
      List<dynamic> localDecoded = [];
      if (localRaw != null) {
        localDecoded = json.decode(localRaw); // Convertir texto plano a lista Dart
      }

      // 2. Agregar el nuevo anuncio (convertido a mapa JSON) a la lista
      localDecoded.add(nuevo.toJson());
      
      // 3. Guardar la lista actualizada serializándola nuevamente a texto plano
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

  // convierte fecha "dd/M/yyyy" a datetime para ordenar
  DateTime _parseFecha(String fecha) {
    try {
      final parts = fecha.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return DateTime(2000);
    }
  }
}
