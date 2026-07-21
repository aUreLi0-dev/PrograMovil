import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/delegate_service.dart';

class DelegadoCursosController extends GetxController {
  final DelegateService _delegateService = DelegateService();

  RxList<CursoDelegado> cursosDelegado = <CursoDelegado>[].obs;
  RxBool cargando = false.obs;

  Future<void> cargarCursos() async {
    cargando.value = true;
    try {
      cursosDelegado.value = await _delegateService.fetchMisCursos();
    } on ApiException catch (e) {
      cursosDelegado.clear();
      Get.snackbar(
        'No se pudieron cargar tus cursos',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      cursosDelegado.clear();
      debugPrint('Error inesperado cargando cursos del delegado: $e');
    } finally {
      cargando.value = false;
    }
  }

  void abrirGestionCurso(CursoDelegado curso) {
    Get.toNamed(
      '/delegado-anuncios',
      arguments: {
        'curso': curso.nombreCurso,
        'idSeccion': curso.idSeccion,
        'codigoSeccion': curso.codigoSeccion,
        'rol': curso.rolTexto,
        'alumnos': curso.alumnosMatriculados,
      },
    );
  }
}
