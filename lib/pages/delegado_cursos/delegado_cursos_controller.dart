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
    cargando.value = true; // Muestra el indicador circular de carga en la pantalla

    try {
      // 1. Obtener al alumno que tiene la sesión iniciada en la aplicación
      final user = AuthService.to.currentUser;
      if (user == null) {
        cursosDelegado.clear();
        return;
      }

      // 2. Cargar todos los cargos de representantes y las matrículas registradas en el sistema
      final representatives = await _representativeService.fetchRepresentatives();
      final enrollments = await _enrollmentService.fetchEnrollments();
      final cursos = <CursoDelegado>[];

      // 3. Cruzar los datos para buscar en cuáles de estos cargos está asignado el alumno actual
      for (final rep in representatives) {
        // Buscar la matrícula (enrollment) que tiene asignado este cargo representativo
        final enrollment = enrollments.firstWhereOrNull(
          (e) => e.id == rep.enrollmentId,
        );

        if (enrollment == null) continue;
        // Si la matrícula no pertenece al alumno logueado, ignoramos esta fila
        if (enrollment.studentCode != user.code) continue;
        // Validar que el rol sea 'delegado' o 'subdelegado'
        if (rep.role != 'delegado' && rep.role != 'subdelegado') continue;

        // Obtener el nombre del curso utilizando su ID
        final curso = _coursesService.getCourseById(enrollment.idCurso);
        if (curso == null) continue;

        // Obtener los datos específicos de la sección (ej. "854") para mostrar el código del salón
        final secciones = curso['secciones'] as List<dynamic>? ?? [];
        final seccion = secciones.firstWhereOrNull(
          (s) => s['idSeccion'].toString() == enrollment.idSeccion,
        );

        // Contar el número total de alumnos matriculados en esta misma sección
        final alumnosMatriculados = enrollments
            .where((e) => e.idSeccion == enrollment.idSeccion)
            .length;

        // 4. Agregar el curso procesado a nuestra lista temporal
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

      // 5. Asignar los cursos a la variable reactiva (.obs) para refrescar la pantalla automáticamente
      cursosDelegado.value = cursos;
    } catch (e) {
      print('Error cargando cursos del delegado: $e');
      cursosDelegado.clear();
    } finally {
      cargando.value = false; // Oculta el indicador de carga al terminar
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
