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
      
      // Obtener las secciones de la base de datos simulada mediante SeccionService
      final secciones = await _seccionService.fetchSecciones();
      final seccionesById = {
        for (final seccion in secciones) seccion.idSeccion: seccion,
      };
      final cursos = <CursoDelegado>[];

      // 3. Cruzar los datos para buscar en cuáles de estos cargos está asignado el alumno actual
      for (final rep in representatives) {
        // Encontrar la matrícula (enrollment) que tiene asignado este cargo representativo
        final enrollment = enrollments.firstWhereOrNull(
          (e) => e.id == rep.enrollmentId,
        );

        if (enrollment == null) continue;
        // Si la matrícula no pertenece al alumno logueado, ignoramos esta fila
        if (enrollment.studentCode != user.code) continue;
        // Validar que el rol sea 'delegado' o 'subdelegado'
        if (rep.role != 'delegado' && rep.role != 'subdelegado') continue;

        // Obtener los datos específicos de la sección (nombre del curso, código del salón, etc.)
        final seccion = seccionesById[enrollment.idSeccion];
        if (seccion == null) continue;

        // Contar el número total de alumnos matriculados en esta misma sección
        final alumnosMatriculados = enrollments
            .where((e) => e.idSeccion == enrollment.idSeccion)
            .length;

        // 4. Agregar el curso procesado a nuestra lista temporal
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
