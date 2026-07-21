import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class SetupCarreraController extends GetxController {
  final carreras = <Map<String, dynamic>>[].obs;
  final especialidadesDisponibles = <Map<String, dynamic>>[].obs;
  final cargandoCarreras = false.obs;
  final cargandoEspecialidades = false.obs;
  final selectedCarreraId = RxnInt();
  final selectedEspecialidades = <int>{}.obs;
  final errorMessage = RxnString();
  final saving = false.obs;

  AuthService get _auth => AuthService.to;

  @override
  void onInit() {
    super.onInit();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    cargandoCarreras.value = true;
    try {
      final api = ApiClient();
      final response = await api.getJson('/api/v1/careers');
      final data = response['data'] as List<dynamic>?;
      if (data != null) {
        carreras.value = data.cast<Map<String, dynamic>>();
      }

      final u = _auth.currentUser;
      if (u?.careerId != null) {
        selectedCarreraId.value = u!.careerId;
        _cargarEspecialidades(u.careerId!);
      } else if (carreras.isNotEmpty) {
        selectedCarreraId.value = carreras.first['id'] as int?;
        _cargarEspecialidades(selectedCarreraId.value!);
      }

      if (u != null && u.especialidades.isNotEmpty) {
        selectedEspecialidades.assignAll(u.especialidades);
      }
    } catch (_) {
      final fallback = _auth.carreras;
      if (fallback.isNotEmpty) {
        carreras.value = fallback;
        if (fallback.isNotEmpty && selectedCarreraId.value == null) {
          selectedCarreraId.value = fallback.first['id'] as int?;
        }
      }
    } finally {
      cargandoCarreras.value = false;
    }
  }

  void onCarreraChanged(int? carreraId) {
    selectedCarreraId.value = carreraId;
    selectedEspecialidades.clear();
    if (carreraId != null) {
      _cargarEspecialidades(carreraId);
    }
  }

  Future<void> _cargarEspecialidades(int carreraId) async {
    cargandoEspecialidades.value = true;
    try {
      final api = ApiClient();
      final response = await api.getJson(
        '/api/v1/specialties',
        query: {'career_id': carreraId.toString()},
      );
      final data = response['data'] as List<dynamic>?;
      if (data != null) {
        especialidadesDisponibles.value = data.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      final fallback = _auth.especialidades
          .where((e) => e['carrera_id'] == carreraId && e['is_active'] == true)
          .toList();
      fallback.sort((a, b) {
        final orderA = (a['display_order'] as num?)?.toInt() ?? 999;
        final orderB = (b['display_order'] as num?)?.toInt() ?? 999;
        return orderA.compareTo(orderB);
      });
      especialidadesDisponibles.value = fallback;
    } finally {
      cargandoEspecialidades.value = false;
    }
  }

  String get selectedCarreraName {
    final id = selectedCarreraId.value;
    if (id == null) return '';
    final match = carreras.firstWhereOrNull((c) => c['id'] == id);
    return match != null ? match['name'] as String : _auth.getCareerName(id);
  }

  void toggleEspecialidad(int id) {
    if (selectedEspecialidades.contains(id)) {
      selectedEspecialidades.remove(id);
    } else {
      selectedEspecialidades.add(id);
    }
  }

  Future<void> finish() async {
    errorMessage.value = null;

    final cId = selectedCarreraId.value;
    if (cId == null) {
      errorMessage.value = 'Por favor, selecciona una carrera.';
      return;
    }

    saving.value = true;
    try {
      await _auth.completeSetup(
        careerId: cId,
        especialidades: selectedEspecialidades.toList(),
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'No pudimos guardar la configuración: $e';
    } finally {
      saving.value = false;
    }
  }
}
