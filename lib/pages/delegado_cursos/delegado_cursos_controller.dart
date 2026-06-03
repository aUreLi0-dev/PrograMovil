import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/section_representative_service.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/enrollment_service.dart';
import 'package:ulima_plus/models/enrollment_model.dart'; 

class DelegadoCursosController {
  List<Map<String, dynamic>> cursosDelegado = [];
  bool cargando = true;

  Future<void> cargarCursos(Function actualizarVista) async {
    cargando = true;
    actualizarVista();

    try {
      final user = AuthService.to.currentUser;
      if (user != null) {
        final allRepresentatives = await SectionRepresentativeService().fetchRepresentatives();
        final enrollmentService = EnrollmentService();
        final allCourses = CoursesService().allCourses;

        List<Map<String, dynamic>> tempCursos = [];

        for (var rep in allRepresentatives) {
          final enrollment = await enrollmentService.findById(rep.enrollmentId);
          
          if (enrollment != null && 
              enrollment.studentCode == user.code && 
              (rep.role == 'delegado' || rep.role == 'subdelegado')) {
            
            for (var curso in allCourses) {
              final secciones = curso['secciones'] as List;
              
              for (var s in secciones) {
                if (s['idSeccion'].toString() == enrollment.idSeccion.toString()) {
                  tempCursos.add({
                    "curso": curso['nombre'],
                    "seccion": enrollment.idSeccion,
                  });
                }
              }
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