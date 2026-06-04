import 'package:get/get.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/enrollment_service.dart';
import 'package:ulima_plus/services/section_representative_service.dart';

class DelegadoCursosController extends GetxController {
  final SectionRepresentativeService _representativeService =
      SectionRepresentativeService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  final CoursesService _coursesService = CoursesService();

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

      final representatives = await _representativeService.fetchRepresentatives();
      final enrollments = await _enrollmentService.fetchEnrollments();
      final cursos = <CursoDelegado>[];

      for (final rep in representatives) {
        final enrollment = enrollments.firstWhereOrNull(
          (e) => e.id == rep.enrollmentId,
        );

        if (enrollment == null) continue;
        if (enrollment.studentCode != user.code) continue;
        if (rep.role != 'delegado' && rep.role != 'subdelegado') continue;

        final curso = _coursesService.getCourseById(enrollment.idCurso);
        if (curso == null) continue;

        final secciones = curso['secciones'] as List<dynamic>? ?? [];
        final seccion = secciones.firstWhereOrNull(
          (s) => s['idSeccion'].toString() == enrollment.idSeccion,
        );

        final alumnosMatriculados = enrollments
            .where((e) => e.idSeccion == enrollment.idSeccion)
            .length;

        cursos.add(
          CursoDelegado(
            idCurso: enrollment.idCurso,
            nombreCurso: curso['nombre'].toString(),
            idSeccion: enrollment.idSeccion,
            codigoSeccion: seccion?['codigoSeccion']?.toString() ??
                enrollment.idSeccion,
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
