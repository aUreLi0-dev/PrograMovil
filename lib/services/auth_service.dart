import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'section_representative_service.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

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
      } catch (_) {      }
    }
  }

  /// Intenta restaurar sesión desde el JWT guardado (API).
  Future<bool> tryAutoLogin() async {
    if (_currentUser.value != null) return true;
    final jwt = _storage.savedJwt;
    if (jwt == null || jwt.isEmpty) return false;

    _loading.value = true;
    try {
      final api = ApiClient();
      final response = await api.getJson('/api/me', token: jwt);
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
      final api = ApiClient();
      final response = await api.postJson(
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

      final meResponse = await api.getJson('/api/me', token: jwt);
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

    final api = ApiClient();
    try {
      await api.postJson(
        '/api/v1/students/${user.id}/setup-career',
        body: {
          'career_id': careerId,
          'specialty_ids': especialidades,
        },
      );
      final meResponse = await api.getJson('/api/me');
      final meData = meResponse['data'] as Map<String, dynamic>?;
      if (meData != null) {
        _currentUser.value = UserModel.fromJson(meData);
      }
    } catch (_) {
      user.careerId = careerId;
      user.especialidades = List.of(especialidades);
      user.setupComplete = true;
      _currentUser.refresh();
    }

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
      final api = ApiClient();
      await api.getJson('/api/sign-out');
    } catch (_) {}
    _currentUser.value = null;
    _isDelegate.value = false;
    _role.value = 'estudiante';
    await _storage.clearSession();
  }
}
