import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DelegadoAnunciosController extends GetxController {
  final TextEditingController titulo = TextEditingController();
  final TextEditingController mensaje = TextEditingController();

  String nombreCurso = 'Curso no especificado';
  String idSeccion = '';
  String codigoSeccion = '';
  String rol = 'Delegado';
  int alumnosMatriculados = 0;

  void cargarCurso(Map<String, dynamic> args) {
    nombreCurso = args['curso']?.toString() ?? nombreCurso;
    idSeccion = args['idSeccion']?.toString() ?? idSeccion;
    codigoSeccion = args['codigoSeccion']?.toString() ?? idSeccion;
    rol = args['rol']?.toString() ?? rol;
    alumnosMatriculados = (args['alumnos'] as num?)?.toInt() ?? 0;
    titulo.clear();
    mensaje.clear();
  }

  void publicarAnuncioPendiente() {
    Get.snackbar(
      'Nuevo anuncio',
      'La publicacion se conectara con anuncios del curso mas adelante.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    titulo.dispose();
    mensaje.dispose();
    super.onClose();
  }
}
