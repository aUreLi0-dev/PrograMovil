import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'section_representative_service.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final ApiClient _apiClient = ApiClient();

  @override
  void onInit() {
    super.onInit();
    _ensureLoaded();
  }

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxList<Map<String, dynamic>> _carreras = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _especialidades =
      <Map<String, dynamic>>[].obs;
  final RxBool _loading = false.obs;
  final RxBool _isDelegate = false.obs;
  final RxString _role = 'estudiante'.obs;

  UserModel? get currentUser => _currentUser.value;
  Rx<UserModel?> get currentUserRx => _currentUser;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isLoading => _loading.value;
  bool get isDelegate => _isDelegate.value;
  String get role => _role.value;

  StorageService get _storage => StorageService.to;

  List<Map<String, dynamic>> get carreras => _carreras;
  List<Map<String, dynamic>> get especialidades => _especialidades;

  String getCareerName(int? id) {
    if (id == null) return '';
    final match = _carreras.firstWhereOrNull((c) => c['id'] == id);
    return match != null ? match['name'] as String : '';
  }

  String getEspecialidadName(int id) {
    final match = _especialidades.firstWhereOrNull((e) => e['id'] == id);
    return match != null ? match['name'] as String : '';
  }

  Future<void> _ensureLoaded() async {
    if (_carreras.isNotEmpty && _especialidades.isNotEmpty) return;

    if (_storage.savedJwt != null && _storage.savedJwt!.isNotEmpty) {
      try {
        final res = await _apiClient.getJson('/api/v1/careers', authenticated: true);
        if (res['success'] == true && res['data'] is List) {
          _carreras.assignAll((res['data'] as List).cast<Map<String, dynamic>>());
        }
      } catch (e) {
        debugPrint('Error al cargar carreras del backend: $e');
      }

      try {
        final res = await _apiClient.getJson('/api/v1/specialties', authenticated: true);
        if (res['success'] == true && res['data'] is List) {
          _especialidades.assignAll((res['data'] as List).cast<Map<String, dynamic>>());
        }
      } catch (e) {
        debugPrint('Error al cargar especialidades del backend: $e');
      }
    }

    if (_carreras.isEmpty) {
      try {
        final rawCarreras = await rootBundle.loadString('assets/data/carreras.json');
        _carreras.assignAll(
          (jsonDecode(rawCarreras) as List).cast<Map<String, dynamic>>(),
        );
      } catch (_) {}
    }

    if (_especialidades.isEmpty) {
      try {
        final rawEspecialidades = await rootBundle.loadString('assets/data/especialidades.json');
        _especialidades.assignAll(
          (jsonDecode(rawEspecialidades) as List).cast<Map<String, dynamic>>(),
        );
      } catch (_) {}
    }
  }

  Future<bool> tryAutoLogin() async {
    if (_currentUser.value != null) return true;
    final jwt = _storage.savedJwt;
    if (jwt == null || jwt.isEmpty) return false;

    _loading.value = true;
    try {
      final response = await _apiClient.getJson('/api/me', token: jwt);
      final userData = response['data'] as Map<String, dynamic>?;
      if (userData == null) return false;

      _currentUser.value = UserModel.fromJson(userData);
      final code = _currentUser.value?.code ?? '';
      if (code.isNotEmpty) {
        await _storage.saveCode(code);
      }
      await refreshDelegateStatus();
      return true;
    } catch (_) {
      await _storage.clearJwt();
      return false;
    } finally {
      _loading.value = false;
    }
  }

  Future<bool> tryRestoreSession() async {
    return await tryAutoLogin();
  }

  Future<String?> login({
    required String code,
    required String password,
  }) async {
    _loading.value = true;
    try {
      final response = await _apiClient.postJson(
        '/api/sign-in',
        body: {'code': code.trim(), 'password': password},
        authenticated: false,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return 'Error al procesar la respuesta';

      final jwt = data['jwt'] as String?;
      if (jwt == null || jwt.isEmpty) return 'No se recibió token de autenticación';

      await _storage.saveJwt(jwt);

      final userData = data['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _currentUser.value = UserModel.fromJson(userData);
      }

      final meResponse = await _apiClient.getJson('/api/me', token: jwt);
      final meData = meResponse['data'] as Map<String, dynamic>?;
      if (meData != null) {
        _currentUser.value = UserModel.fromJson(meData);
      }

      final userCode = _currentUser.value?.code ?? '';
      if (userCode.isNotEmpty) {
        await _storage.saveCode(userCode);
      }
      await refreshDelegateStatus();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de conexión: $e';
    } finally {
      _loading.value = false;
    }
  }

  Future<void> completeSetup({
    required int careerId,
    required List<int> especialidades,
  }) async {
    final user = _currentUser.value;
    if (user == null) return;

    final u = _currentUser.value!;
    u.careerId = careerId;
    u.especialidades = List.of(especialidades);
    u.setupComplete = true;
    _currentUser.refresh();
    await _storage.saveSetupFor(
      code: u.code,
      careerId: careerId,
      especialidades: especialidades,
      setupComplete: true,
    );

    try {
      final studentId = u.studentId ?? u.id;
      if (studentId == null) {
        debugPrint('No se pudo enviar setup al backend: studentId nulo.');
        return;
      }
      await _apiClient.postJson(
        '/api/v1/students/$studentId/setup-career',
        body: {
          'career_id': careerId,
          'specialty_ids': especialidades,
        },
      );
      debugPrint('Configuración de carrera guardada con éxito en el backend.');
    } catch (e) {
      debugPrint('Error al guardar configuración de carrera en backend: $e');
    }
  }

  Future<void> updateEspecialidades(List<int> especialidades) async {
    final u = _currentUser.value;
    if (u == null) return;
    u.especialidades = List.of(especialidades);
    _currentUser.refresh();
    final careerId = u.careerId;
    if (careerId != null) {
      await _storage.saveSetupFor(
        code: u.code,
        careerId: careerId,
        especialidades: especialidades,
        setupComplete: u.setupComplete,
      );

      try {
        final studentId = u.studentId ?? u.id;
        if (studentId == null) {
          debugPrint('No se pudo actualizar especialidades en backend: studentId nulo.');
          return;
        }
        await _apiClient.postJson(
          '/api/v1/students/$studentId/setup-career',
          body: {
            'career_id': careerId,
            'specialty_ids': especialidades,
          },
        );
        debugPrint('Especialidades actualizadas con éxito en el backend.');
      } catch (e) {
        debugPrint('Error al actualizar especialidades en backend: $e');
      }
    }
  }

  Future<void> refreshDelegateStatus() async {
    final code = _currentUser.value?.code;
    if (code == null) {
      _isDelegate.value = false;
      _role.value = 'estudiante';
      return;
    }

    final repService = SectionRepresentativeService();
    _isDelegate.value = await repService.isRepresentativeInAnySection(code);
    _role.value = await repService.findHighestRoleByStudentCode(code);
  }

  Future<void> logout() async {
    try {
      await _apiClient.getJson('/api/sign-out');
    } catch (_) {}
    _currentUser.value = null;
    _isDelegate.value = false;
    _role.value = 'estudiante';
    await _storage.clearSession();
  }
}
