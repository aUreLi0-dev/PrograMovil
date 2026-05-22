import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/anuncio_model.dart';

class AnuncioService {
  // Obtiene anuncios desde el JSON filtrando por el ID de la sección
  Future<List<Anuncio>> fetchAnuncios(String idSeccion) async {
    try {
      // 1. Carga el archivo JSON
      final String response = await rootBundle.loadString('assets/data/anuncios.json');

      // 2. Convierte el JSON
      final data = json.decode(response);
      final List<dynamic> anunciosRaw = data['anuncios'] ?? [];

      // 3. Convierte cada mapa a AnuncioModel
      final todosLosAnuncios = anunciosRaw.map((a) => Anuncio.fromJson(a)).toList();

      // 4. EL PASO CLAVE: Filtramos la lista para que coincida con el idSeccion
      // Nota: Si en tu modelo Anuncio la variable se llama 'idSeccion', usa anuncio.idSeccion.
      // Si dejaste el nombre original del JSON, usa anuncio.cursoId.
      return todosLosAnuncios.where((anuncio) => anuncio.cursoId == idSeccion).toList();
      
    } catch (e) {
      print("Error cargando anuncios: $e");
      return []; // Si hay un error, devolvemos una lista vacía en lugar de romper la app
    }
  }
}