import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/services/section_representative_service.dart';

class DelegadoCursosController extends GetxController {
  final SectionRepresentativeService _representativeService =
      SectionRepresentativeService();

  RxList<CursoDelegado> cursosDelegado = <CursoDelegado>[].obs;
  RxBool cargando = false.obs;

  Future<void> cargarCursos() async {
    cargando.value = true;

    try {
      cursosDelegado.value = await _representativeService.fetchDelegateSections(
        force: true,
      );
    } catch (e) {
      debugPrint('Error cargando cursos del delegado: $e');
      cursosDelegado.clear();
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
