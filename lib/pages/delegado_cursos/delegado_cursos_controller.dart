import 'package:get/get.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/enrollment_service.dart';
import 'package:ulima_plus/services/section_representative_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

class DelegadoCursosController extends GetxController {
  final SectionRepresentativeService _representativeService =
      SectionRepresentativeService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  final SeccionService _seccionService = SeccionService();

  RxList<CursoDelegado> cursosDelegado = <CursoDelegado>[].obs;
  RxBool cargando = false.obs;

  Future<void> cargarCursos() async {
    cargando.value = true;

    try {
      final user = AuthService.to.currentUser;
      if (user == null) {
        cursosDelegado.clear();
        return;
      }

      final representatives = await _representativeService
          .fetchRepresentatives();
      final enrollments = await _enrollmentService.fetchEnrollments();
      final secciones = await _seccionService.fetchSecciones();
      final seccionesById = {
        for (final seccion in secciones) seccion.idSeccion: seccion,
      };
      final cursos = <CursoDelegado>[];

      for (final rep in representatives) {
        final enrollment = enrollments.firstWhereOrNull(
          (e) => e.id == rep.enrollmentId,
        );

        if (enrollment == null) continue;
        if (enrollment.studentCode != user.code) continue;
        if (rep.role != 'delegado' && rep.role != 'subdelegado') continue;

        final seccion = seccionesById[enrollment.idSeccion];
        if (seccion == null) continue;

        final alumnosMatriculados = enrollments
            .where((e) => e.idSeccion == enrollment.idSeccion)
            .length;

        cursos.add(
          CursoDelegado(
            idCurso: enrollment.idCurso,
            nombreCurso: seccion.curso,
            idSeccion: seccion.idSeccion,
            codigoSeccion: seccion.codigoSeccion.isNotEmpty
                ? seccion.codigoSeccion
                : seccion.idSeccion,
            rol: rep.role,
            alumnosMatriculados: alumnosMatriculados,
          ),
        );
      }

      cursosDelegado.value = cursos;
    } catch (e) {
      print('Error cargando cursos del delegado: $e');
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
