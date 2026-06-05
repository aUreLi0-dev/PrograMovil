// lib/services/auth_service.dart
// Autenticación con JSON local + persistencia de sesión via StorageService.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../models/user_model.dart';
import 'notas_service.dart';
import 'section_representative_service.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxList<Map<String, dynamic>> _users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _carreras = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _especialidades =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _userEspecialidades =
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

  /// Carga el catálogo de usuarios mock desde assets (idempotente).
  Future<void> _ensureLoaded() async {
    if (_users.isNotEmpty &&
        _carreras.isNotEmpty &&
        _especialidades.isNotEmpty &&
        _userEspecialidades.isNotEmpty) {
      return;
    }

    final raw = await rootBundle.loadString('assets/data/users.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['users'] as List).cast<Map<String, dynamic>>();
    _users.assignAll(list);

    final rawCarreras = await rootBundle.loadString(
      'assets/data/carreras.json',
    );
    _carreras.assignAll(
      (jsonDecode(rawCarreras) as List).cast<Map<String, dynamic>>(),
    );

    final rawEspecialidades = await rootBundle.loadString(
      'assets/data/especialidades.json',
    );
    _especialidades.assignAll(
      (jsonDecode(rawEspecialidades) as List).cast<Map<String, dynamic>>(),
    );

    final rawUserEspecialidades = await rootBundle.loadString(
      'assets/data/user_especialidades.json',
    );
    _userEspecialidades.assignAll(
      (jsonDecode(rawUserEspecialidades) as List).cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> _withEspecialidadesFromRelation(
    Map<String, dynamic> userJson,
  ) {
    final copy = Map<String, dynamic>.from(userJson);
    final userCode = copy['code'].toString();
    final userEspIds = _userEspecialidades
        .where((ue) => ue['user_code'].toString() == userCode)
        .map((ue) => (ue['especialidad_id'] as num).toInt())
        .toList();

    if (userEspIds.isNotEmpty) {
      copy['especialidades'] = userEspIds;
    }
    return copy;
  }

  void _applySavedSetup(UserModel user) {
    if (!_storage.hasSavedSetupFor(user.code)) return;

    final careerId = _storage.savedCareerIdFor(user.code);
    if (careerId != null) user.careerId = careerId;

    user.especialidades = _storage.savedEspecialidadesFor(user.code);
    user.setupComplete = _storage.savedSetupCompleteFor(user.code);
  }

  /// Intenta restaurar la sesión guardada en local storage.
  /// Devuelve true si se restauró correctamente.
  Future<bool> tryRestoreSession() async {
    final code = _storage.savedCode;
    if (code == null) return false;
    await _ensureLoaded();
    final match = _users.firstWhereOrNull((u) => u['code'].toString() == code);
    if (match == null) {
      await _storage.clearSession();
      return false;
    }
    final user = UserModel.fromJson(_withEspecialidadesFromRelation(match));
    // Aplicar datos de setup guardados.
    _applySavedSetup(user);

    _currentUser.value = user;
    // Vincula las notas guardadas a este alumno (clave notas_estudiante_<code>).
    await NotasService().guardarIdEstudianteActual(code);
    await refreshDelegateStatus();
    return true;
  }

  /// Intenta autenticar al usuario. Devuelve null si OK, o mensaje de error.
  Future<String?> login({
    required String code,
    required String password,
  }) async {
    _loading.value = true;
    try {
      await _ensureLoaded();
      final normalizedCode = code.trim();
      final match = _users.firstWhereOrNull(
        (u) => u['code'].toString() == normalizedCode,
      );
      if (match == null) return 'No encontramos un alumno con ese código.';
      final storedPassword =
          match['password_hash'] as String? ?? match['password'] as String?;
      if (storedPassword != password) {
        return 'La contraseña no es correcta.';
      }

      final user = UserModel.fromJson(_withEspecialidadesFromRelation(match));
      _applySavedSetup(user);
      _currentUser.value = user;
      await _storage.saveCode(normalizedCode);
      // Vincula las notas guardadas a este alumno (clave notas_estudiante_<code>).
      await NotasService().guardarIdEstudianteActual(normalizedCode);
      await refreshDelegateStatus();
      return null;
    } catch (e) {
      return 'Ocurrió un error inesperado: $e';
    } finally {
      _loading.value = false;
    }
  }

  /// Actualiza carrera/especialidades del usuario actual y marca el setup completo.
  Future<void> completeSetup({
    required int careerId,
    required List<int> especialidades,
  }) async {
    final u = _currentUser.value;
    if (u == null) return;
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

  /// Actualiza solo las especialidades del alumno (desde el perfil) y las
  /// persiste, sin tocar el flag de setup ni navegar.
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
    _currentUser.value = null;
    _isDelegate.value = false;
    _role.value = 'estudiante';
    await _storage.clearSession();
  }
}
