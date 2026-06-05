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

  // Reactivo para las estadísticas del salón
  final Rxn<EstadisticasSeccion> estadisticas = Rxn<EstadisticasSeccion>();

  void cargarCurso(Map<String, dynamic> args) {
    nombreCurso = args['curso']?.toString() ?? nombreCurso;
    idSeccion = args['idSeccion']?.toString() ?? idSeccion;
    codigoSeccion = args['codigoSeccion']?.toString() ?? idSeccion;
    rol = args['rol']?.toString() ?? rol;
    alumnosMatriculados = (args['alumnos'] as num?)?.toInt() ?? 0;
    titulo.clear();
    mensaje.clear();

    // Cargar estadísticas realistas según la sección
    if (codigoSeccion.contains('854') || nombreCurso.toLowerCase().contains('móvil') || nombreCurso.toLowerCase().contains('movil')) {
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 14.5,
        porcentajeAprobados: 74,
        rango0_10: 2,
        rango11_13: 5,
        rango14_16: 12,
        rango17_20: 8,
      );
    } else if (codigoSeccion.contains('856') || nombreCurso.toLowerCase().contains('software')) {
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 15.8,
        porcentajeAprobados: 85,
        rango0_10: 1,
        rango11_13: 3,
        rango14_16: 15,
        rango17_20: 9,
      );
    } else {
      // Valores por defecto consistentes para cualquier otro curso
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 15.0,
        porcentajeAprobados: 80,
        rango0_10: 2,
        rango11_13: 4,
        rango14_16: 14,
        rango17_20: 7,
      );
    }
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

class EstadisticasSeccion {
  final double promedioGeneral;
  final int porcentajeAprobados;
  final int rango0_10;
  final int rango11_13;
  final int rango14_16;
  final int rango17_20;

  EstadisticasSeccion({
    required this.promedioGeneral,
    required this.porcentajeAprobados,
    required this.rango0_10,
    required this.rango11_13,
    required this.rango14_16,
    required this.rango17_20,
  });
}

