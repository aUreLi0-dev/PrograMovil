import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/pages/malla/malla_controller.dart';

class PerfilController extends GetxController {
  AuthService get _auth => AuthService.to;

  UserModel? get user => _auth.currentUser;

  String get nombre {
    final u = user;
    if (u == null) return '';
    return '${u.lastName} ${u.firstName}'.toUpperCase();
  }

  String get carrera {
    final u = user;
    if (u == null) return '';
    return _auth.getCareerName(u.careerId);
  }

  String get especialidad {
    final u = user;
    if (u == null) return '';
    return u.especialidades
        .map((id) => _auth.getEspecialidadName(id))
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  String get roleLabel {
    switch (_auth.role) {
      case 'delegado':
        return 'DELEGADO';
      case 'subdelegado':
        return 'SUBDELEGADO';
      default:
        return 'ALUMNO';
    }
  }

  List<Map<String, dynamic>> getEspecialidadesDisponibles(int careerId) {
    final disponibles = _auth.especialidades
        .where(
            (e) => e['carrera_id'] == careerId && e['is_active'] == true)
        .toList();
    disponibles.sort((a, b) {
      final oa = (a['display_order'] as num?)?.toInt() ?? 999;
      final ob = (b['display_order'] as num?)?.toInt() ?? 999;
      return oa.compareTo(ob);
    });
    return disponibles;
  }

  Future<void> guardarEspecialidades(Set<int> seleccion) async {
    await _auth.updateEspecialidades(seleccion.toList());
    if (Get.isRegistered<MallaController>()) {
      Get.find<MallaController>().reloadForUser();
    }
  }
}
