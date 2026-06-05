import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/section_representative_service.dart';
import 'package:ulima_plus/services/enrollment_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

class DelegadoCursosController {
  List<Map<String, dynamic>> cursosDelegado = [];
  bool cargando = true;

  Future<void> cargarCursos(Function actualizarVista) async {
    cargando = true;
    actualizarVista();

    try {
      final user = AuthService.to.currentUser;
      if (user != null) {
        final allRepresentatives = await SectionRepresentativeService()
            .fetchRepresentatives();
        final enrollmentService = EnrollmentService();
        final secciones = await SeccionService().fetchSecciones();
        final seccionesById = {
          for (final seccion in secciones) seccion.idSeccion: seccion,
        };

        final tempCursos = <Map<String, dynamic>>[];

        for (final rep in allRepresentatives) {
          final enrollment = await enrollmentService.findById(rep.enrollmentId);

          if (enrollment != null &&
              enrollment.studentCode == user.code &&
              (rep.role == 'delegado' || rep.role == 'subdelegado')) {
            final seccion = seccionesById[enrollment.idSeccion];
            if (seccion != null) {
              tempCursos.add({
                "curso": seccion.curso,
                "seccion": seccion.codigoSeccion,
                "idSeccion": seccion.idSeccion,
              });
            }
          }
        }

        cursosDelegado = tempCursos;
      }
    } catch (e) {
      print("Error cargando cursos del delegado: $e");
    } finally {
      cargando = false;
      actualizarVista();
    }
  }
}
