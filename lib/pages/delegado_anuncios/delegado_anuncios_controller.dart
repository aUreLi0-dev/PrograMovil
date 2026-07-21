import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/estadisticas_seccion_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/delegate_service.dart';

class DelegadoAnunciosController extends GetxController {
  final DelegateService _delegateService = DelegateService();

  final TextEditingController titulo = TextEditingController();
  final TextEditingController mensaje = TextEditingController();

  String nombreCurso = 'Curso no especificado';
  String idSeccion = '';
  String codigoSeccion = '';
  String rol = 'Delegado';
  int alumnosMatriculados = 0;

  // Estadísticas del salón (null mientras cargan o si falla; la UI muestra vacío).
  final Rxn<EstadisticasSeccion> estadisticas = Rxn<EstadisticasSeccion>();

  void cargarCurso(Map<String, dynamic> args) {
    // 1. Datos que llegan de la pantalla anterior (lista de cursos).
    nombreCurso = args['curso']?.toString() ?? nombreCurso;
    idSeccion = args['idSeccion']?.toString() ?? idSeccion;
    codigoSeccion = args['codigoSeccion']?.toString() ?? idSeccion;
    rol = args['rol']?.toString() ?? rol;
    alumnosMatriculados = (args['alumnos'] as num?)?.toInt() ?? 0;

    // 2. Limpiar el formulario.
    titulo.clear();
    mensaje.clear();

    // 3. Pedir las estadísticas reales del salón al backend.
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final sectionId = int.tryParse(idSeccion);
    if (sectionId == null) return;
    try {
      estadisticas.value = await _delegateService.fetchEstadisticas(sectionId);
    } on ApiException catch (e) {
      estadisticas.value = null;
      debugPrint('Error cargando estadísticas: ${e.message}');
    }
  }

  Future<void> publicarAnuncio() async {
    // 1. Validar que no estén vacíos.
    if (titulo.text.trim().isEmpty || mensaje.text.trim().isEmpty) {
      Get.snackbar(
        'Campos vacíos',
        'Por favor, ingrese un título y mensaje para el anuncio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final sectionId = int.tryParse(idSeccion);
    if (sectionId == null) {
      Get.snackbar(
        'Error',
        'La sección no es válida.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 2. Enviar al backend. Él valida (con el JWT) que seas delegado de la sección
    //    y guarda al autor; por eso no mandamos datos del usuario.
    try {
      await _delegateService.publicarAnuncio(
        sectionId: sectionId,
        titulo: titulo.text.trim(),
        mensaje: mensaje.text.trim(),
      );

      // 3. Éxito: avisar, limpiar y volver a la pantalla anterior.
      Get.snackbar(
        'Publicado',
        'Anuncio publicado correctamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      titulo.clear();
      mensaje.clear();
      Get.back();
    } on ApiException catch (e) {
      // Ej: 403 si no eres delegado de esa sección, o 401 sin token.
      Get.snackbar(
        'No se pudo publicar',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    titulo.dispose();
    mensaje.dispose();
    super.onClose();
  }
}
