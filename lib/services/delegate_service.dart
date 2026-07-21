import '../models/anuncio_model.dart';
import '../models/curso_delegado_model.dart';
import '../models/estadisticas_seccion_model.dart';
import 'api_client.dart';

/// Conecta el módulo de Delegado con el backend Flask.
///
/// Cada método corresponde a un endpoint. No maneja errores aquí a propósito:
/// si algo falla, [ApiClient] lanza una [ApiException] que el controlador
/// atrapa y muestra en pantalla. Así el servicio queda corto y legible.
class DelegateService {
  final ApiClient _apiClient = ApiClient();

  /// 1. Cursos/secciones donde el usuario logueado es delegado o subdelegado.
  /// GET /api/v1/delegate/sections
  /// (El backend identifica al alumno por el JWT; no hay que mandar su id.)
  Future<List<CursoDelegado>> fetchMisCursos() async {
    final res = await _apiClient.getJson('/api/v1/delegate/sections');
    final data = res['data'] as List? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CursoDelegado.fromJson)
        .toList();
  }

  /// 2. Anuncios de una sección (el backend los devuelve del más nuevo al más viejo).
  /// GET /api/v1/sections/{sectionId}/announcements
  /// [sectionId] puede ser el id numérico ("1") o el código ("IS-856");
  /// el backend resuelve ambos.
  Future<List<Anuncio>> fetchAnuncios(String sectionId) async {
    final res = await _apiClient.getJson(
      '/api/v1/sections/$sectionId/announcements',
    );
    final data = res['data'] as List? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => Anuncio.fromJson(json))
        .toList();
  }

  /// 3. Publica un anuncio en la sección.
  /// POST /api/v1/delegate/announcements
  /// El backend valida con el JWT que de verdad seas delegado de esa sección.
  /// No devuelve nada: si no lanza excepción, se publicó bien.
  Future<void> publicarAnuncio({
    required int sectionId,
    required String titulo,
    required String mensaje,
  }) async {
    await _apiClient.postJson(
      '/api/v1/delegate/announcements',
      body: {'section_id': sectionId, 'title': titulo, 'message': mensaje},
    );
  }

  /// 4. Estadísticas de notas de la sección (para el gráfico de barras).
  /// GET /api/v1/sections/{sectionId}/statistics
  Future<EstadisticasSeccion> fetchEstadisticas(int sectionId) async {
    final res = await _apiClient.getJson(
      '/api/v1/sections/$sectionId/statistics',
    );
    return EstadisticasSeccion.fromJson(res['data'] as Map<String, dynamic>);
  }
}
