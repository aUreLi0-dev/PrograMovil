// lib/pages/login/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/alertas_service.dart';
import '../../services/auth_service.dart';

class LoginController extends GetxController {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final errorMessage = RxnString();
  final submitting = false.obs;

  AuthService get _auth => AuthService.to;

  Future<void> submit() async {
    final code = codeController.text.trim();
    final password = passwordController.text;

    if (code.isEmpty || password.isEmpty) {
      errorMessage.value = 'Ingresa tu código y contraseña.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;

    final error = await _auth.login(code: code, password: password);

    submitting.value = false;

    if (error != null) {
      errorMessage.value = error;
      return;
    }

    // Regenera las alertas del alumno que inicia sesión (badge reactivo).
    // Defensivo: nunca debe bloquear el login si el servicio no está listo.
    if (Get.isRegistered<AlertasService>()) {
      AlertasService.to.generarAlertas();
    }
    final user = _auth.currentUser;
    Get.offAllNamed(
      user != null && user.setupComplete ? '/home' : '/setup-carrera',
    );
  }

  @override
  void onClose() {
    codeController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
