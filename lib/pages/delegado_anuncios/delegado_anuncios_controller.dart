import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/services/anuncio_service.dart';
import 'package:ulima_plus/services/auth_service.dart';

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

  void publicarAnuncio() async {
    // 1. Validar que los campos no estén vacíos
    if (titulo.text.trim().isEmpty || mensaje.text.trim().isEmpty) {
      Get.snackbar(
        'Campos vacíos',
        'Por favor, ingrese un título y mensaje para el anuncio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // 2. Obtener el usuario logueado
    final user = AuthService.to.currentUser;
    if (user == null) {
      Get.snackbar(
        'Error',
        'No se pudo identificar la sesión del usuario.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 3. Obtener la fecha actual (ej. 23/2/2026)
    final ahora = DateTime.now();
    final fechaFormateada = '${ahora.day}/${ahora.month}/${ahora.year}';

    // 4. Instanciar el objeto Anuncio con un ID único basado en el tiempo
    final nuevoAnuncio = Anuncio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idSeccion: idSeccion,
      titulo: titulo.text.trim(),
      mensaje: mensaje.text.trim(),
      fecha: fechaFormateada,
      autorCode: user.code,
      autorName: user.fullName,
      autorRole: rol,
    );

    // 5. Guardar mediante el servicio
    final response = await AnuncioService().addAnuncio(nuevoAnuncio);

    if (response.success) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Anuncio publicado correctamente.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Limpiar campos del formulario
      titulo.clear();
      mensaje.clear();

      // Regresar a la pantalla anterior
      Get.back();
    } else {
      Get.snackbar(
        'Error',
        'No se pudo publicar el anuncio: ${response.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    titulo.dispose();
    mensaje.dispose();
    super.onClose();
  }
}

